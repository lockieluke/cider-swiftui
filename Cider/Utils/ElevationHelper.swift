//
//  ElevationHelper.swift
//  Cider
//
//  Created by Sherlock LUK on 24/11/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation

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
    
}
