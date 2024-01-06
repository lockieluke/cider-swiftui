//
//  CiderUpdaterProtocol.swift
//  CiderUpdater
//
//  Created by Sherlock LUK on 26/11/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyJSON

class CiderUpdateManifest: NSObject, Codable {
    
    let version: String
    let build: Int
    let downloadLink: URL
    let downloadHash: String
    var dmgPath: String {
        return "Cider-\(self.version)-\(self.build).dmg"
    }
    
    init(
        version: String,
        build: Int,
        downloadLink: URL,
        downloadHash: String
    ) {
        self.version = version
        self.build = build
        self.downloadLink = downloadLink
        self.downloadHash = downloadHash
    }
    
}

/// The protocol that this service will vend as its API. This protocol will also need to be visible to the process hosting the service.
@objc protocol CiderUpdateServiceProtocol {
    
    func fetchPresentVersion() async throws -> Data
    func removeQuarantineFlag(path: String, reply onReply: @escaping (_ error: Error) -> Void)
    func applyUpdate(manifestData: Data, dmgPath: String, parentPid: Int32, appPath: String) async throws
    
}

/*
 To use the service from an application or other process, use NSXPCConnection to establish a connection to the service by doing something like this:

     connectionToService = NSXPCConnection(serviceName: "com.cidercollective.CiderUpdater")
     connectionToService.remoteObjectInterface = NSXPCInterface(with: CiderUpdaterProtocol.self)
     connectionToService.resume()

 Once you have a connection to the service, you can use it like this:

     if let proxy = connectionToService.remoteObjectProxy as? CiderUpdaterProtocol {
         proxy.performCalculation(firstNumber: 23, secondNumber: 19) { result in
             NSLog("Result of calculation is: \(result)")
         }
     }

 And, when you are finished with the service, clean up the connection like this:

     connectionToService.invalidate()
*/
