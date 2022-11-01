//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import Swifter
import SwiftyJSON
import ArgumentParserKit

class AppDelegate : NSObject, NSApplicationDelegate {
    
    private let server = HttpServer()
    private let serverFallback = HttpResponse.movedPermanently("https://discord.com/invite/applemusic")
    private var musicKitWorker: MusicKitWorker?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let argParser = ArgumentParser(usage: "<options>", overview: "\(Bundle.main.procName)")
        
        let agentPortOption = argParser.add(option: "--agent-port", kind: Int.self)
        let userTokenOption = argParser.add(option: "--am-user-token", kind: String.self)
        let developerTokenOption = argParser.add(option: "--am-token", kind: String.self)
        
        guard let parsedArguments = try? argParser.parse(Array(CommandLine.arguments.dropFirst())) else {
            fatalError("Failed to parse arguments")
        }
        let agentPort = parsedArguments.get(agentPortOption)
        guard let userToken = parsedArguments.get(userTokenOption) else { fatalError("Invalid user token") }
        guard let developerToken = parsedArguments.get(developerTokenOption) else { fatalError("Invalid developer token") }
        
        NSApp.setActivationPolicy(.accessory)
        self.musicKitWorker = MusicKitWorker(userToken: userToken, developerToken: developerToken)
        
        server["/"] = { request in
            if !isReqFromCider(request.headers) {
                return self.serverFallback
            }
            
            return .ok(.text("HELLO WORLD"))
        }
        
        server["/shutdown"] = { request in
            if !isReqFromCider(request.headers) {
                return self.serverFallback
            }
            
            let json = JSON(["message": "\(Bundle.main.procName) is shutting down"])
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.musicKitWorker?.dispose()
                self.musicKitWorker = nil
                self.server.stop()
                NSApp.terminate(nil)
            }
            return .ok(.text(json.rawString()!))
        }
        
        let defaultPort = Bundle.main.infoDictionary?["DEFAULT_PORT"] as! Int
        
        do {
            try server.start(UInt16(agentPort ?? defaultPort))
        } catch {
            fatalError("\(Bundle.main.executableURL?.lastPathComponent ?? "This application encountered an error"): \(error)")
        }
    }
    
}

let appDelegate = AppDelegate()
autoreleasepool {
    NSApplication.shared.delegate = appDelegate
    NSApplication.shared.run()
}
