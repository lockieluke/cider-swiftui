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
        let configOption = argParser.add(option: "--config", kind: String.self)
        
        guard let parsedArguments = try? argParser.parse(Array(CommandLine.arguments.dropFirst())) else {
            fatalError("Failed to parse arguments: \(CommandLine.arguments.dropFirst())")
        }
        let agentPort = parsedArguments.get(agentPortOption)
        guard let agentSessionId = parsedArguments.get(agentSessionIdOption)?.replacingOccurrences(of: "\"", with: "") else { fatalError("Agent session ID is not present") }
        guard let userToken = parsedArguments.get(userTokenOption) else { fatalError("Invalid user token") }
        guard let developerToken = parsedArguments.get(developerTokenOption) else { fatalError("Invalid developer token") }
        guard let configRaw = parsedArguments.get(configOption) else { fatalError("Invalid config") }
        
        guard let config = try? JSON(data: configRaw.data(using: .utf8)!) else { fatalError("Failed to parse config") }
        
        NSApp.setActivationPolicy(.accessory)
        self.musicKitWorker = MusicKitWorker(userToken: userToken, developerToken: developerToken, config: config)
        
        server["/ws"] = websocket(text: { session, text in
            let json = try? JSON(data: text.data(using: .utf8)!)
            guard let route = json?["route"].string,
                  let requestId = json?["requestId"].string
            else {
                session.writeCloseFrame()
                return
            }
            
            if !isReqFromCider(session.request?.headers ?? [:], agentSessionId: agentSessionId) {
                session.writeCloseFrame()
                return
            }
            
            let requestObj = JSON([
                "requestId": requestId
            ])
            let done = {
                if let rawString = requestObj.rawString() {
                    session.writeText(rawString)
                }
            }
            
            Task {
                switch route {
                    
                case "/":
                    session.writeText("CiderPlaybackAgent on port \(agentPort?.formatted() ?? "Default Port")")
                    break
                    
                case "/set-audio-quality":
                    await self.musicKitWorker?.setAudioQuality(audioQuality: json?["quality"].int ?? 64)
                    break
                    
                case "/set-queue":
                    if let albumId = json?["albums-id"].string {
                        await self.musicKitWorker?.setQueueWithAlbumID(albumID: albumId)
                    } else if let playlistId = json?["playlists-id"].string {
                        await self.musicKitWorker?.setQueueWithPlaylistID(playlistID: playlistId)
                    } else if let songId = json?["songs-id"].string {
                        await self.musicKitWorker?.setQueueWithSongID(songID: songId)
                    }
                    break
                    
                case "/set-shuffle-mode":
                    if let shuffleMode = json?["shuffle"].bool {
                        await self.musicKitWorker?.setShuffleMode(shuffleMode)
                    }
                    break
                    
                case "/set-repeat-mode":
                    if let repeatMode = json?["repeat-mode"].string {
                        await self.musicKitWorker?.setRepeatMode(repeatMode)
                    }
                    break
                    
                case "/play":
                    if let shuffle = json?["shuffle"].bool {
                        await self.musicKitWorker?.setShuffleMode(shuffle)
                    }
                    await self.musicKitWorker?.play()
                    break
                    
                case "/pause":
                    await self.musicKitWorker?.pause()
                    break
                    
                case "/previous":
                    await self.musicKitWorker?.previous()
                    break
                    
                case "/next":
                    await self.musicKitWorker?.next()
                    break
                    
                default:
                    break
                }
                
                done()
            }
        }, connected: { session in
            print("Cider Client connected")
            
            self.musicKitWorker?.addCallback { eventName, dict in
                var requestObj = JSON()
                let done = {
                    if let rawString = requestObj.rawString() {
                        session.writeText(rawString)
                    }
                }
                
                requestObj["requestId"].string = UUID().uuidString
                requestObj["eventName"].string = eventName
                switch eventName {
                    
                case "mediaItemDidChange":
                    requestObj["mediaParams"] = JSON([
                        "name": dict["name"],
                        "artistName": dict["artistName"],
                        "artworkURL": dict["artworkURL"]
                    ])
                    break
                    
                case "playbackStateDidChange":
                    requestObj["playbackState"].string = String(describing: dict["playbackState"] ?? "unknown" as AnyObject)
                    break
                    
                case "playbackTimeDidChange":
                    requestObj["currentTime"].int = dict["currentTime"] as? Int
                    requestObj["remainingTime"].int = dict["remainingTime"] as? Int
                    break
                    
                case "playbackDurationDidChange":
                    requestObj["duration"].int = dict["duration"] as? Int
                    break
                    
                default:
                    break
                    
                }
                done()
            }
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
        
        do {
            print("websocketcomm.ready")
        }
    }
    
}

let appDelegate = AppDelegate()
autoreleasepool {
    NSApplication.shared.delegate = appDelegate
    NSApplication.shared.run()
}
