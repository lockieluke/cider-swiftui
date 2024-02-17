//
//  CiderUpdaterService.swift
//  CiderUpdaterService
//
//  Created by Sherlock LUK on 26/11/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import Files
import System
import Subprocess
import SwiftyUtils
import AppKit

extension URL {
    func listExtendedAttributes() throws -> [String] {
        let list = try self.withUnsafeFileSystemRepresentation { fileSystemPath -> [String] in
            let length = listxattr(fileSystemPath, nil, 0, 0)
            guard length >= 0 else { throw URL.posixError(errno) }
            
            // Create buffer with required size:
            var namebuf = Array<CChar>(repeating: 0, count: length)
            
            // Retrieve attribute list:
            let result = listxattr(fileSystemPath, &namebuf, namebuf.count, 0)
            guard result >= 0 else { throw URL.posixError(errno) }
            
            // Extract attribute names:
            let list = namebuf.split(separator: 0).compactMap {
                $0.withUnsafeBufferPointer {
                    $0.withMemoryRebound(to: UInt8.self) {
                        String(bytes: $0, encoding: .utf8)
                    }
                }
            }
            return list
        }
        return list
    }
    
    private static func posixError(_ err: Int32) -> NSError {
        return NSError(domain: NSPOSIXErrorDomain, code: Int(err),
                       userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(err))])
    }
}

/// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
class CiderUpdateService: NSObject, CiderUpdateServiceProtocol {
    
    private var observation: NSKeyValueObservation?
    private var isUpdateInProgress: Bool = false
    
    func removeQuarantineFlag(path: String, reply onReply: @escaping (_ error: Error) -> Void) {
        do {
            if (try URL(filePath: path).listExtendedAttributes().contains("com.apple.quarantine")) {
                if removexattr(path, "com.apple.quarantine", XATTR_NOFOLLOW) != 0 {
                    let error = Errno(rawValue: errno)
                    onReply(error)
                }
            }
        } catch {
            onReply(error)
        }
    }
    
    func applyUpdate(manifestData: Data, dmgPath: String, parentPid: Int32, appPath: String) async throws {
        ProcessInfo.processInfo.disableAutomaticTermination("Update in progress")
        self.isUpdateInProgress = true
        
        let appPath = try Folder(path: appPath)
        let updateBundle = try Folder.temporary.createSubfolderIfNeeded(withName: Bundle.main.bundleIdentifier!).createSubfolderIfNeeded(at: "Updates")
        let newAppBundlePath = "\(updateBundle.path)/Cider.app"
        
        do {
            try appPath.delete()
        } catch {
            throw NSError(domain: "Failed to remove old app bundle", code: 1)
        }
        
        if kill(parentPid, SIGTERM) != 0 {
            let error = Errno(rawValue: errno)
            print("Failed to kill parent process: \(error.localizedDescription)")
            return
        }
        
        print("Mounting \(dmgPath) to \(updateBundle.path)")
        try await Subprocess(["/usr/bin/hdiutil", "attach", "-readonly", "-mountpoint", updateBundle.path, dmgPath]).run().waitUntilExit()
        
        try FileManager.default.copyItem(atPath: newAppBundlePath, toPath: appPath.path)
        
        print("Unmount dmg")
        try await Subprocess(["/sbin/umount", "-f", updateBundle.path]).run().waitUntilExit()
        
        try File(path: dmgPath).delete()
        try updateBundle.delete()
        
        try await NSWorkspace.shared.openApplication(at: appPath.url, configuration: NSWorkspace.OpenConfiguration().then {
            $0.arguments = ["-show-changelogs"]
        })
        exit(0)
    }
    
    func cleanup() {
        if self.isUpdateInProgress {
            return
        }
        
        exit(0)
    }
    
}
