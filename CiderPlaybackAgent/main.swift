//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import AppKit
import ArgumentParser
import Swifter
import SwiftyJSON
import SwiftyUtils

struct CiderPlaybackAgent: ParsableCommand {
    
    // doesn't strip quotes
    @Option(name: .long)
    private var agentSessionId: String
    
    @Option(name: .customLong("am-token"))
    private var developerToken: String
    
    @Option(name: .customLong("am-user-token"))
    private var userToken: String
    
    @Option(name: .long)
    private var agentPort: Int
    
    @Option(name: .customLong("config"))
    private var configRaw: String
    
    class AppDelegate : NSObject, NSApplicationDelegate {
        
        private let server = HttpServer()
        private let serverFallback: HttpResponse = .movedPermanently("https://discord.com/invite/applemusic")
        private var musicKitWorker: MusicKitWorker?
        
        private let agentSessionId: String
        private let userToken: String
        private let developerToken: String
        private let agentPort: Int
        private let configRaw: String
        
        init(agentSessionId: String, userToken: String, developerToken: String, agentPort: Int, configRaw: String) {
            self.agentSessionId = agentSessionId
            self.userToken = userToken
            self.developerToken = developerToken
            self.agentPort = agentPort
            self.configRaw = configRaw
        }
        
        func applicationDidFinishLaunching(_ notification: Notification) {
            if let currentAppleEvent = NSAppleEventManager.shared().currentAppleEvent, let parentPid = currentAppleEvent.attributeDescriptor(forKeyword: keySenderPIDAttr)?.int32Value {
                suicide_if_we_become_a_zombie(parentPid)
            }

            let config = JSON(parseJSON: configRaw)
            
            self.musicKitWorker = MusicKitWorker(userToken: self.userToken, developerToken: self.developerToken, config: config)
            
            server["/ws"] = websocket(text: { session, text in
                let json = try? JSON(data: text.data(using: .utf8)!)
                guard let route = json?["route"].string,
                      let requestId = json?["requestId"].string
                else {
                    session.writeCloseFrame()
                    return
                }
                
                if !isReqFromCider(session.request?.headers ?? [:], agentSessionId: self.agentSessionId) {
                    session.writeCloseFrame()
                    return
                }
                
                var requestObj = JSON([
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
                        session.writeText("CiderPlaybackAgent on port \(self.agentPort)")
                        break
                        
                    case "/set-audio-quality":
                        await self.musicKitWorker?.setAudioQuality(audioQuality: json?["quality"].int ?? 64)
                        break
                        
                    case "/set-volume":
                        if let volume = json?["volume"].double {
                            self.musicKitWorker?.setVolume(volume: volume)
                        }
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
                        
                    case "/skip-to-queue-index":
                        if let index = json?["index"].int {
                            await self.musicKitWorker?.skipToQueueIndex(index)
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
                        
                    case "/set-autoplay":
                        if let autoPlay = json?["autoplay"].bool {
                            await self.musicKitWorker?.setAutoPlay(autoPlay)
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
                        
                    case "/stop":
                        await self.musicKitWorker?.stop()
                        break
                        
                    case "/seek-to-time":
                        if let seconds = json?["seconds"].int {
                            await self.musicKitWorker?.seekToTime(seconds: seconds)
                        }
                        break
                        
                    case "/previous":
                        await self.musicKitWorker?.previous()
                        break
                        
                    case "/next":
                        await self.musicKitWorker?.next()
                        break
                        
                    case "/reorder-queued-item":
                        if let from = json?["from"].int, let to = json?["to"].int {
                            await self.musicKitWorker?.reorderQueuedItem(from: from, to: to)
                        }
                        break
                        
                    case "/open-airplay-picker":
                        let supportsAirPlay = await self.musicKitWorker?.openAirPlayPicker(x: json?["x"].int, y: json?["y"].int)
                        requestObj["supportsAirPlay"].bool = supportsAirPlay
                        break
                        
                    case "/open-inspector":
                        self.musicKitWorker?.openInspectorInNewWindow()
                        break
                        
                    default:
                        break
                    }
                    
                    done()
                }
            }, connected: { session in
                print("Cider Client connected")
                
                var requestObj = JSON()
                let done = {
                    if let rawString = requestObj.rawString() {
                        session.writeText(rawString)
                    }
                }
                
                self.musicKitWorker?.addCallback { eventName, dict in
                    Task {
                        requestObj["requestId"].string = UUID().uuidString
                        requestObj["eventName"].string = eventName
                        switch eventName {
                            
                        case "mediaItemDidChange":
                            let artworkURL = dict["artworkURL"]
                            requestObj["mediaParams"] = JSON([
                                "id": dict["id"],
                                "name": dict["name"],
                                "artistName": dict["artistName"],
                                "artworkURL": artworkURL
                            ])
                            break
                            
                        case "playbackStateDidChange":
                            requestObj["playbackState"].string = String(describing: dict["playbackState"] ?? "unknown" as AnyObject)
                            break
                            
                        case "playbackTimeDidChange":
                            requestObj["currentTime"].int = dict["currentTime"] as? Int
                            requestObj["remainingTime"].int = dict["remainingTime"] as? Int
                            break
                            
                        case "queueItemsDidChange":
                            requestObj["queue"] = JSON(dict["items"] as Any)
                            break
                            
                        case "playbackDurationDidChange":
                            requestObj["duration"].int = dict["duration"] as? Int
                            break
                            
                        default:
                            break
                            
                        }
                        done()
                    }
                }
            })
            
            server["/shutdown"] = { request in
                if !isReqFromCider(request.headers, agentSessionId: self.agentSessionId) {
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
            
            do {
                try server.start(UInt16(self.agentPort))
            } catch {
                fatalError("Failed to start CiderPlaybackAgent server")
            }
            
            print("websocketcomm.ready")
        }
        
    }
    
    mutating func run() throws {
        let appDelegate = AppDelegate(
            agentSessionId: agentSessionId.unquote(),
            userToken: userToken,
            developerToken: developerToken,
            agentPort: agentPort,
            configRaw: configRaw
        )
        NSApplication.shared.delegate = appDelegate
        NSApp.setActivationPolicy(.accessory)
        NSApplication.shared.run()
    }
    
}

autoreleasepool {
    CiderPlaybackAgent.main()
}
