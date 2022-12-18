//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import Starscream
import SwiftyJSON

struct NowPlayingState {
    
    var name: String? = nil
    var artistName: String? = nil
    var artworkURL: URL?
    var isPlaying = false
    var isReady = true
    
    mutating func reset() {
        self.name = nil
        self.artworkURL = nil
        self.artistName = nil
        self.isPlaying = false
    }
    
}

struct PlaybackBehaviour {
    
    var shuffle: Bool = false
    
}

class CiderPlayback : ObservableObject, WebSocketDelegate {
    
    @Published var nowPlayingState = NowPlayingState()
    @Published var playbackBehaviour = PlaybackBehaviour()
    @Published var isReady = false
    
    let agentPort: UInt16
    let agentSessionId: String
    
    private let logger: Logger
    private let proc: Process
    private let wsCommClient: CiderWSProvider
    private let commClient: NetworkingProvider
    private var isRunning: Bool
    
    init(prefModal: PrefModal) {
        let logger = Logger(label: "CiderPlayback")
        let agentPort = NetworkingProvider.findFreeLocalPort()
        let agentSessionId = UUID().uuidString
        self.wsCommClient = CiderWSProvider(baseURL: URL(string: "ws://localhost:\(agentPort)/ws")!, wsTarget: .CiderPlaybackAgent, defaultHeaders:  [
            "Agent-Session-ID": agentSessionId,
            "User-Agent": "Cider SwiftUI"
        ])
        self.commClient = NetworkingProvider(baseURL: URL(string: "http://127.0.0.1:\(agentPort)")!, defaultHeaders: [
            "Agent-Session-ID": agentSessionId,
            "User-Agent": "Cider SwiftUI"
        ])
        
        // hack to access self before everything is initialised
        weak var weakSelf: CiderPlayback?
        
        let proc = Process()
        let pipe = Pipe()
        pipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if data.isEmpty {
                fileHandle.readabilityHandler = nil
            } else {
                guard let str = String(data: data, encoding: .utf8) else {
                    fileHandle.readabilityHandler = nil
                    return
                }
                var newStr = str
                if let last = newStr.last {
                    if last.isNewline {
                        newStr.removeLast()
                    }
                }
                
                if newStr == "websocketcomm.ready" {
                    weakSelf?.wsCommClient.delegate = weakSelf
                    weakSelf?.wsCommClient.connect()
                } else {
                    logger.info("[CiderPlaybackAgent] \(newStr)")
                }
            }
        }
        
        guard let execUrl = Bundle.main.sharedSupportURL?.appendingPathComponent("CiderPlaybackAgent") else { fatalError("Error finding CiderPlaybackAgent") }
        proc.arguments = [
            "--agent-port", String(agentPort),
            "--agent-session-id", "\"\(agentSessionId)\"",
            "--config", "\(prefModal.prefs.rawJSONString)"
        ]
        proc.executableURL = execUrl
        proc.standardOutput = pipe
        
        self.logger = logger
        self.agentSessionId = agentSessionId
        self.proc = proc
        self.agentPort = agentPort
        self.isRunning = false
        
        weakSelf = self
    }
    
    func setDeveloperToken(developerToken: String) {
        if !self.isRunning {
            self.proc.arguments?.append(contentsOf: ["--am-token", developerToken])
        }
    }
    
    func setUserToken(userToken: String) {
        if !self.isRunning {
            self.proc.arguments?.append(contentsOf: ["--am-user-token", userToken])
        }
    }
    
    func setQueue(musicItem: MusicItem) async {
        await self.setQueue(requestBody: ["\(musicItem.type.rawValue)-id": musicItem.id])
    }
    
    func setQueue(mediaTrack: MediaTrack) async {
        await self.setQueue(requestBody: ["\(mediaTrack.type.rawValue)-id": mediaTrack.id])
    }
    
    func setQueue(requestBody: [String : Any]? = nil) async {
        do {
            _ = try await self.wsCommClient.request("/set-queue", body: requestBody)
        } catch {
            self.logger.error("Set Queue failed \(error)", displayCross: true)
        }
    }
    
    func setShuffleMode(_ shuffle: Bool) async {
        self.playbackBehaviour.shuffle = shuffle
        do {
            _ = try await self.wsCommClient.request("/set-shuffle-mode", body: [
                "shuffle": shuffle
            ])
        } catch {
            self.logger.error("Set shuffle mode failed \(error)", displayCross: true)
        }
    }
    
    func play(shuffle: Bool = false) async {
        self.playbackBehaviour.shuffle = shuffle
        do {
            _ = try await self.wsCommClient.request("/play", body: [
                "shuffle": shuffle
            ])
        } catch {
            self.logger.error("Play failed \(error)", displayCross: true)
        }
    }
    
    func pause() async {
        do {
            _ = try await self.wsCommClient.request("/pause")
        } catch {
            self.logger.error("Pause failed \(error)", displayCross: true)
        }
    }
    
    enum SkipType {
        case Previous, Next
    }
    func skip(type: SkipType) async {
        do {
            _ = try await self.wsCommClient.request(type == .Previous ? "/previous" : "/next")
        } catch {
            self.logger.error("Skip failed \(error)", displayCross: true)
        }
    }
    
    func togglePlaybackSync() {
        Task {
            await (self.nowPlayingState.isPlaying ? self.pause() : self.play())
        }
    }
    
    func setAudioQuality(_ quality: AudioQuality) async {
        do {
            _ = try await self.wsCommClient.request("/set-audio-quality", body: [
                "quality": quality.rawValue
            ])
        } catch {
            self.logger.error("Failed to set audio quality to \(quality.rawValue)", displayCross: true)
        }
    }
    
    func start() {
        if self.isRunning {
            return
        }
        
        do {
            try proc.run()
            self.isRunning = true
            self.logger.info("CiderPlaybackAgent on port \(self.agentPort) with Session ID \(self.agentSessionId)")
        } catch {
            self.logger.error("Error running CiderPlaybackAgent: \(error)")
        }
    }
    
    func updateNowPlayingStateBeforeReady(mediaTrack: MediaTrack) {
        self.nowPlayingState = NowPlayingState(
            name: mediaTrack.title,
            artistName: mediaTrack.artistName,
            artworkURL: mediaTrack.artwork.getUrl(width: 100, height: 100),
            isPlaying: false,
            isReady: false
        )
    }
    
    func updateNowPlayingStateBeforeReady(musicItem: MusicItem) {
        self.nowPlayingState = NowPlayingState(
            name: musicItem.title,
            artistName: musicItem.artistName,
            artworkURL: musicItem.artwork.getUrl(width: 100, height: 100),
            isPlaying: false,
            isReady: false
        )
    }
    
    func shutdown() async {
        do {
            _ = try await self.commClient.request("/shutdown")
        } catch {
            self.logger.error("Error shutting down CiderPlaybackAgent: \(error)")
        }
    }
    
    func shutdownSync() {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            await self.shutdown()
            semaphore.signal()
        }
        semaphore.wait()
    }
    
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
            
        case .connected:
            self.isReady = true
            self.logger.success("Connected to CiderPlaybackAgent", displayTick: true)
            break
            
        case .error(let error):
            guard let error = error else { return }
            self.logger.error("WebSockets error: \(error)")
            break
            
        case .text(let message):
            guard let json = try? JSON(data: message.data(using: .utf8)!),
                  let eventName = json["eventName"].string,
                  let requestId = json["requestId"].string
            else { return }
            
            WSModal.shared.traffic.append(WSTrafficRecord(target: .CiderPlaybackAgent, rawJSONString: message, dateSent: .now, trafficType: .Receive, requestId: requestId))
            
            switch eventName {
                
            case "mediaItemDidChange":
                let mediaParams = json["mediaParams"]
                
                self.nowPlayingState.name = mediaParams["name"].string
                self.nowPlayingState.artistName = mediaParams["artistName"].string
                
                let newArtworkURL = URL(string: mediaParams["artworkURL"].stringValue.replacingOccurrences(of: "{w}", with: "100").replacingOccurrences(of: "{h}", with: "100"))
                if newArtworkURL != self.nowPlayingState.artworkURL {
                    self.nowPlayingState.artworkURL = newArtworkURL
                }
                
                self.nowPlayingState.isPlaying = true
                self.nowPlayingState.isReady = true
                
                break
                
            case "playbackStateDidChange":
                switch json["playbackState"].string {
                    
                case "paused":
                    self.nowPlayingState.isPlaying = false
                    break
                    
                case "stopped":
                    self.nowPlayingState.reset()
                    break
                    
                case "playing":
                    self.nowPlayingState.isPlaying = true
                    self.nowPlayingState.isReady = true
                    break
                    
                default:
                    break
                    
                }
                break
                
            default:
                break
                
            }
            
            break
            
        default:
            break
            
        }
    }
    
}
