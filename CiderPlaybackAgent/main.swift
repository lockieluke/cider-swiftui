//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import ArgumentParserKit
import GCDWebServer

class AppDelegate : NSObject, NSApplicationDelegate {
    
    private var agentSessionId: String!
    private let server = GCDWebServer()
    private let serverFallback = GCDWebServerResponse(redirect: URL(string: "https://discord.com/invite/applemusic")!, permanent: true)
    private var musicKitWorker: MusicKitWorker?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let argParser = ArgumentParser(usage: "<options>", overview: "\(Bundle.main.procName)")
        
        let agentPortOption = argParser.add(option: "--agent-port", kind: Int.self)
        let agentSessionIdOption = argParser.add(option: "--agent-session-id", kind: String.self)
        let userTokenOption = argParser.add(option: "--am-user-token", kind: String.self)
        let developerTokenOption = argParser.add(option: "--am-token", kind: String.self)
        
        guard let parsedArguments = try? argParser.parse(Array(CommandLine.arguments.dropFirst())) else {
            fatalError("Failed to parse arguments: \(CommandLine.arguments.dropFirst())")
        }
        let agentPort = parsedArguments.get(agentPortOption)
        guard let agentSessionId = parsedArguments.get(agentSessionIdOption)?.replacingOccurrences(of: "\"", with: "") else { fatalError("Agent session ID is not present") }
        guard let userToken = parsedArguments.get(userTokenOption) else { fatalError("Invalid user token") }
        guard let developerToken = parsedArguments.get(developerTokenOption) else { fatalError("Invalid developer token") }
        
        NSApp.setActivationPolicy(.accessory)
        self.musicKitWorker = MusicKitWorker(userToken: userToken, developerToken: developerToken)
        
        server.addHandler(forMethod: "GET", path: "/", request: GCDWebServerRequest.self) { request in
            if !isReqFromCider(request.headers, agentSessionId: agentSessionId) {
                return self.serverFallback
            }
            
            return GCDWebServerDataResponse(text: "HELLO WORLD")
        }
        
        server.addHandler(forMethod: "POST", path: "/set-queue", request: GCDWebServerURLEncodedFormRequest.self) { request, response in
            let request = request as! GCDWebServerURLEncodedFormRequest
            if !isReqFromCider(request.headers, agentSessionId: agentSessionId) {
                response(self.serverFallback)
            }

            Task {
                if let albumId = request.arguments["album-id"] {
                    await self.musicKitWorker?.setQueueWithAlbumID(albumID: albumId)
                }

                response(GCDWebServerDataResponse(text: "Added to queue"))
            }
        }

        server.addHandler(forMethod: "GET", path: "/play", request: GCDWebServerDataRequest.self) { request, response in
            if !isReqFromCider(request.headers, agentSessionId: agentSessionId) {
                response(self.serverFallback)
            }
            
            Task {
                await self.musicKitWorker?.play()

                response(GCDWebServerDataResponse(text: "Playing"))
            }
        }

        server.addHandler(forMethod: "GET", path: "/shutdown", request: GCDWebServerDataRequest.self) { request, response in
            if !isReqFromCider(request.headers, agentSessionId: agentSessionId) {
                response(self.serverFallback)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.musicKitWorker?.dispose()
                self.musicKitWorker = nil
                self.server.stop()
                NSApp.terminate(nil)
            }
            response(GCDWebServerDataResponse(statusCode: 200))
        }

        let defaultPort = Bundle.main.infoDictionary?["DEFAULT_PORT"] as! Int

        server.start(withPort: UInt(agentPort ?? defaultPort), bonjourName: nil)
    }
    
}

let appDelegate = AppDelegate()
autoreleasepool {
    NSApplication.shared.delegate = appDelegate
    NSApplication.shared.run()
}
