//
//  ElevationHelper.swift
//  Cider
//
//  Created by Sherlock LUK on 24/11/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import ZippyJSON

class ElevationHelper {
    
    static let shared = ElevationHelper()
    
    let xpc: CiderElevationHelperProtocol
    
    private let connection: NSXPCConnection
    private let helperId: String = "com.cidercollective.CiderElevationHelper"
    private let logger: Logger
    
    init() {
        let logger = Logger(label: "ElevationHelper")
        
        self.connection = NSXPCConnection(serviceName: helperId).then {
            let interface = NSXPCInterface(with: CiderElevationHelperProtocol.self)
            $0.invalidationHandler = {
                logger.error("XPC connection to ElevationHelper has been invalidated")
            }
            $0.remoteObjectInterface = interface
        }
        self.logger = logger
        self.xpc = self.connection.remoteObjectProxyWithErrorHandler { error in
            logger.error(error.localizedDescription, displayCross: true)
        } as! CiderElevationHelperProtocol
    }
    
    func start() {
        self.connection.resume()
        self.logger.success("Started")
        
        self.xpc.initialiseDiscordRpc()
    }
    
    func terminate() {
        self.xpc.cleanup()
        self.connection.invalidate()
    }
    
    func isDiscordInstalled() async -> Bool {
        return await withCheckedContinuation { continuation in
            self.xpc.isDiscordInstalled { isInstalled in
                continuation.resume(returning: isInstalled)
            }
        }
    }
    
    func retrieveDiscordUsername() async -> String? {
        return await withCheckedContinuation { continuation in
            self.xpc.retrieveDiscordUsername { username in
                continuation.resume(returning: username)
            }
        }
    }
    
    func retrieveDiscordId() async -> String? {
        return await withCheckedContinuation { continuation in
            self.xpc.retrieveDiscordId { id in
                continuation.resume(returning: id)
            }
        }
    }
    
    func retrieveAppleIdInformation() async -> AppleIdInformation? {
        return await withCheckedContinuation { continuation in
            self.xpc.retrieveAppleIdInformation { data in
                if !data.isNil {
                    do {
                        let info = try ZippyJSONDecoder().decode(AppleIdInformation.self, from: data!)
                        
                        continuation.resume(returning: info)
                    } catch {
                        self.logger.error("Failed to retrieve Apple ID info: \(error.localizedDescription)")
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
    
}
