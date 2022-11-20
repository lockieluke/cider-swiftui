//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import ArgumentParserKit
import Swifter
import SwiftyJSON

class AppDelegate : NSObject, NSApplicationDelegate {
    
    private var agentSessionId: String!
    private let server = HttpServer()
    private let serverFallback: HttpResponse = .movedPermanently("https://discord.com/invite/applemusic")
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
        
        server["/ws"] = websocket(text: { session, text in        
            let json = try? JSON(data: text.data(using: .utf8)!)
            guard let route = json?["route"].string,
                  let requestId = json?["request-id"].string
            else {
                session.writeCloseFrame()
                return
            }
            
            if !isReqFromCider(session.request?.headers ?? [:], agentSessionId: agentSessionId) {
                session.writeCloseFrame()
                return
            }
            
            let done = {
                session.writeText(JSON([
                    "request-id": requestId
                ]).rawString()!)
            }
            
            switch route {
                
            case "/":
                session.writeText("CiderPlaybackAgent on port \(agentPort?.formatted() ?? "Default Port")")
                break
                
            case "/set-queue":
                Task {
                    if let albumId = json?["album-id"].string {
                        await self.musicKitWorker?.setQueueWithAlbumID(albumID: albumId)
                    } else if let playlistId = json?["playlist-id"].string {
                        await self.musicKitWorker?.setQueueWithPlaylistID(playlistID: playlistId)
                    }
                    done()
                }
                break
                
            case "/play":
                Task {
                    await self.musicKitWorker?.play()
                    done()
                }
                break
                
            default:
                break
            }
        }, connected: { session in
            print("Cider Client connected")
        })
        
        server["/shutdown"] = { request in
            if !isReqFromCider(request.headers, agentSessionId: agentSessionId) {
                return self.serverFallback
            }
            
            DispatchQueue.main.async {
                self.musicKitWorker?.dispose()
                self.musicKitWorker = nil
                self.server.stop()
                NSApp.terminate(nil)
            }
            
            return .ok(.text("Shutting down"))
        }

        let defaultPort = Bundle.main.infoDictionary?["DEFAULT_PORT"] as! Int
        do {
            try server.start(UInt16(agentPort ?? defaultPort))
        } catch {
            fatalError("Failed to start CiderPlaybackAgent server")
        }
    }
    
}

let appDelegate = AppDelegate()
autoreleasepool {
    NSApplication.shared.delegate = appDelegate
    NSApplication.shared.run()
}
