//
//  UpdateHelper.swift
//  Cider
//
//  Created by Sherlock LUK on 04/12/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import ZippyJSON
import SwiftyJSON
import Files
import CryptoKit
import System
import Subprocess
import FirebaseCore
import FirebaseStorage
import FirebaseFirestore

extension File {
    
    var sha256Hash: String? {
        if let fileData = try? self.read() {
            let hash = SHA256.hash(data: fileData)
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        }
        
        return nil
    }
    
}

class UpdateHelper: ObservableObject {
    
    static let shared = UpdateHelper()
    
    private let xpc: CiderUpdateServiceProtocol
    
    private let connection: NSXPCConnection
    private var downloadObservation: NSKeyValueObservation?
    private var extractionObservation: NSKeyValueObservation?
    private let helperId: String = "com.cidercollective.UpdaterService"
    private var storage: FirebaseStorage.Storage?
    private var firestore: Firestore?
    
    let logger: Logger
    var updateManifest: CiderUpdateManifest?
    @Published var updateNeeded: Bool = false
    
    init() {
        let logger = Logger(label: "UpdateHelper")
        
        self.connection = NSXPCConnection(serviceName: helperId).then {
            let interface = NSXPCInterface(with: CiderUpdateServiceProtocol.self)
            $0.invalidationHandler = {
                logger.error("XPC connection to UpdateHelper has been invalidated")
            }
            $0.remoteObjectInterface = interface
        }
        self.logger = logger
        self.xpc = self.connection.remoteObjectProxyWithErrorHandler { error in
            logger.error("\(error.localizedDescription)", displayCross: true)
        } as! CiderUpdateServiceProtocol
    }
    
    func start() {
        self.connection.resume()
        self.logger.success("Started")
        
        // Defer firebase initialisation
        self.storage = FirebaseStorage.Storage.storage()
        self.firestore = Firestore.firestore().then {
            $0.settings = FirestoreSettings().then {
                $0.cacheSettings = MemoryCacheSettings(garbageCollectorSettings: MemoryLRUGCSettings())
            }
        }
        
        self.firestore?.collection("app").document("releases").collection("macos-native").document("present").addSnapshotListener { snapshot, error in
            if let error = error {
                self.logger.error("Failed to pull update information: \(error.localizedDescription)")
                return
            }
            
            if !snapshot.isNil {
                Task {
                    self.logger.info("New version just dropped, fetching update manifest")
                    if let updateManifest = await UpdateHelper.shared.fetchPresentVersion() {
                        DispatchQueue.main.async {
                            self.updateManifest = updateManifest
                            self.updateNeeded = self.isAppVersionOutdated(manifest: updateManifest)
                        }
                    }
                }
            }
        }
    }
    
    func terminate() {
        self.connection.invalidate()
    }
    
    func fetchPresentVersion() async -> CiderUpdateManifest? {
        do {
            let data = try await self.xpc.fetchPresentVersion()
            
            return try ZippyJSONDecoder().decode(CiderUpdateManifest.self, from: data)
        } catch {
            self.logger.error("Failed to fetch present version from update server: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func fetchCurrentChangelogs() async -> String? {
        do {
            // Fetch using CiderUpdateService - slower but independent
//            let data = try await self.xpc.fetchCurrentChangelogs(version: Bundle.main.appVersion, build: Int(Bundle.main.appBuild) ?? 0)
            
            if let data = try await self.storage?.reference(withPath: "changelogs/macos-native").child("Cider-\(Bundle.main.appVersion)-b\(Bundle.main.appBuild).md").data(maxSize: .max) {
                return String(data: data, encoding: .utf8)
            }
        } catch {
            self.logger.error("Failed to fetch current changelog: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func downloadUpdate(manifest: CiderUpdateManifest, _ onDownloadProgress: @escaping (_ progress: Double) -> Void, _ onDownloadError: @escaping (_ error: String) -> Void, _ onDownloadComplete: @escaping () -> Void) {
        let _onDownloadComplete = { (data: Data) in
            guard let dmg = try? Folder.temporary.createFileIfNeeded(at: manifest.dmgPath) else {
                onDownloadError("Error creating file handle for DMG")
                return
            }
            
            do {
                try dmg.write(data)
            } catch {
                self.logger.error("Failed to write or extract DMG in TMPDIR: \(error.localizedDescription)")
                return
            }
            
            self.xpc.removeQuarantineFlag(path: dmg.path) { error in
                self.logger.error("Failed to remove quarantine flag from \(dmg.path): \(error.localizedDescription)")
            }
            
            onDownloadComplete()
        }
        
        if Folder.temporary.containsFile(at: manifest.dmgPath), let file = try? Folder.temporary.file(at: manifest.dmgPath), let data = try? file.read() {
            if file.sha256Hash == manifest.downloadHash {
                self.logger.success("Recovering update archive")
                _onDownloadComplete(data)
                return
            }
        }
        self.logger.info("Downloading update to Version \(manifest.version) (\(manifest.build))")
        
        let task = URLSession.shared.dataTask(with: manifest.downloadLink) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else { return }
            if let error = error {
                onDownloadError(error.localizedDescription)
                return
            }
            
            if !httpResponse.ok {
                onDownloadError("Download resulted in status code \(httpResponse.statusCode)")
                return
            }
            
            self.downloadObservation?.invalidate()
            if let data = data {
                _onDownloadComplete(data)
            }
        }
        self.downloadObservation = task.progress.observe(\.fractionCompleted) { progress, _ in
            onDownloadProgress(progress.fractionCompleted)
        }
        
        task.resume()
    }
    
    func applyUpdate(manifest: CiderUpdateManifest) async {
        self.logger.info("Applying update \(manifest.version) (\(manifest.build))")
        do {
            try await self.xpc.applyUpdate(
                manifestData: try JSONEncoder().encode(manifest),
                dmgPath: Folder.temporary.file(named: manifest.dmgPath).path,
                parentPid: ProcessInfo.processInfo.processIdentifier,
                appPath: Bundle.main.bundlePath
            )
        } catch {
            self.logger.error("Failed to apply update: \(error.localizedDescription)")
        }
    }
    
    func isAppVersionOutdated(manifest: CiderUpdateManifest) -> Bool {
        return manifest.version != Bundle.main.appVersion || manifest.build != (Int(Bundle.main.appBuild) ?? 0)
    }
    
}
