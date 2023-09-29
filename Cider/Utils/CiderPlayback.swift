//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import Foundation
import Starscream
import SwiftyJSON
import Throttler
import Defaults
import SwiftUI
import Alamofire
import Subprocess

struct NowPlayingState {
    
    var item: MediaDynamic?
    var name: String? = nil, artistName: String? = nil
    var contentRating: String?
    var artworkURL: URL?
    var isPlaying = false, isReady = true, hasItemToPlay = false, playbackPipelineInitialised = false
    var currentTime: TimeInterval?
    var remainingTime: TimeInterval?
    var duration: TimeInterval = 0.0
    
    mutating func reset() {
        self.item = nil
        self.name = nil
        self.contentRating = nil
        self.artworkURL = nil
        self.artistName = nil
        self.isPlaying = false
        self.isReady = true
        self.hasItemToPlay = false
        self.currentTime = nil
        self.remainingTime = nil
        self.duration = 0.0
    }
    
}

enum RepeatMode: String, CaseIterable {
    case None = "none" , All = "all", One = "one"
}

struct PlaybackBehaviour {
    
    var shuffle = false
    var repeatMode: RepeatMode = .None
    var autoplayEnabled: Bool
    var volume = 1.0
    
    init() {
        self.autoplayEnabled = Defaults[.playbackAutoplay]
    }
    
}

class CiderPlayback : ObservableObject, WebSocketDelegate {
    
    @Published var nowPlayingState = NowPlayingState()
    @Published var playbackBehaviour = PlaybackBehaviour()
    @Published var isReady = false
    
    let agentPort: UInt16
    let agentSessionId: String
    
    private let logger: Logger
    private let appWindowModal: AppWindowModal
#if os(macOS)
    private let discordRPCModal: DiscordRPCModal!
    private var proc: Subprocess
    private let procUrl: String
    private let defaultArguments: [String]
    private var additionalArguments: [String] = []
#endif
    private let wsCommClient: CiderWSProvider
    private let commClient: NetworkingProvider
    
    private var mkModal: MKModal?
    private var isRunning: Bool
    
    var queue: [MediaTrack] = []
    
#if os(macOS)
    typealias DiscordRPCModalOrNil = DiscordRPCModal
#else
    typealias DiscordRPCModalOrNil = NSObject
#endif
    
    init(appWindowModal: AppWindowModal, discordRPCModal: DiscordRPCModalOrNil? = nil) {
        let logger = Logger(label: "CiderPlayback")
        let agentPort = Networking.findFreeLocalPort()
        let agentSessionId = UUID().uuidString
        self.wsCommClient = CiderWSProvider(baseURL: URL(string: "http://localhost:\(agentPort)/ws")!, wsTarget: .CiderPlaybackAgent, defaultHeaders:  [
            "Agent-Session-ID": agentSessionId,
            "User-Agent": "Cider SwiftUI"
        ])
        self.commClient = NetworkingProvider(baseURL: URL(string: "http://127.0.0.1:\(agentPort)")!, defaultHeaders: [
            "Agent-Session-ID": agentSessionId,
            "User-Agent": "Cider SwiftUI"
        ])
        
#if os(macOS)
        let procUrl: String
        if #available(macOS 13.0, *) {
            procUrl = (Bundle.main.bundleURL.appendingPathComponent("Contents").appendingPathComponent("SharedSupport").appendingPathComponent("CiderPlaybackAgent").path(percentEncoded: false))
        } else {
            procUrl = (Bundle.main.bundleURL.appendingPathComponent("Contents").appendingPathComponent("SharedSupport").appendingPathComponent("CiderPlaybackAgent").path)
        }
        var config = JSON([
            "openWebInspectorAutomatically": false
        ])
        let proc = Subprocess([procUrl])
#endif
        
#if DEBUG
        config["openWebInspectorAutomatically"].boolValue = Defaults[.debugOpenWebInspectorAutomatically]
#endif
        
#if os(macOS)
        self.defaultArguments = [
            "--agent-port", String(agentPort),
            "--agent-session-id", "\"\(agentSessionId)\"",
            "--config", config.rawString(.utf8)!
        ]
#endif
        
        self.logger = logger
        self.appWindowModal = appWindowModal
        self.agentSessionId = agentSessionId
#if os(macOS)
        self.proc = proc
        self.procUrl = procUrl
        self.discordRPCModal = discordRPCModal
#endif
        self.agentPort = agentPort
        self.isRunning = false
    }
    
    func setDeveloperToken(developerToken: String, mkModal: MKModal) {
        if !self.isRunning {
#if os(macOS)
            self.additionalArguments += ["--am-token", developerToken]
            self.proc = Subprocess([self.procUrl] + self.defaultArguments + self.additionalArguments)
#endif
        }
        self.mkModal = mkModal
    }
    
    func setUserToken(userToken: String) {
        if !self.isRunning {
#if os(macOS)
            self.additionalArguments += ["--am-user-token", userToken]
            self.proc = Subprocess([self.procUrl] + self.defaultArguments + self.additionalArguments)
#endif
        }
    }
    
    @MainActor
    func setQueue(item: MediaDynamic) async {
        let type, id: String
        switch item {
            
        case .mediaItem(let mediaItem):
            type = mediaItem.type.rawValue
            id = mediaItem.id
            
        case .mediaTrack(let mediaTrack):
            type = "songs"
            id = mediaTrack.id
            
        case .mediaPlaylist(let mediaPlaylist):
            type = "playlists"
            id = mediaPlaylist.id
            
        }
        
        await self.setQueue(requestBody: ["\(type)-id": id])
    }
    
    @MainActor
    func skipToQueueIndex(_ index: Int) async {
        do {
            _ = try await self.wsCommClient.request("/skip-to-queue-index", body: [
                "index": index
            ])
        } catch {
            self.logger.error("Skip to queue index \(index) failed \(error)", displayCross: true)
        }
    }
    
    @MainActor
    func setQueue(requestBody: [String : Any]? = nil) async {
        do {
            _ = try await self.wsCommClient.request("/set-queue", body: requestBody)
        } catch {
            self.logger.error("Set Queue failed \(error)", displayCross: true)
        }
    }
    
    @MainActor
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
    
    @MainActor
    func setRepeatMode(_ repeatMode: RepeatMode) async {
        self.playbackBehaviour.repeatMode = repeatMode
        do {
            _ = try await self.wsCommClient.request("/set-repeat-mode", body: [
                "repeat-mode": repeatMode.rawValue
            ])
        } catch {
            self.logger.error("Set repeat mode failed \(error)", displayCross: true)
        }
    }
    
    @MainActor
    func setAutoPlay(_ autoPlay: Bool) async {
        self.playbackBehaviour.autoplayEnabled = autoPlay
        do {
            _ = try await self.wsCommClient.request("/set-autoplay", body: [
                "autoplay": autoPlay
            ])
        } catch {
            self.logger.error("Set autoplay failed \(error)", displayCross: true)
        }
    }
    
    @MainActor
    func clearAndPlay(shuffle: Bool = false, item: MediaDynamic) async {
        await self.stop()
        await self.play(shuffle: shuffle)
    }
    
    @MainActor
    func play(shuffle: Bool = false) async {
        DispatchQueue.main.async {
            self.playbackBehaviour.shuffle = shuffle
        }
        do {
            _ = try await self.wsCommClient.request("/play", body: [
                "shuffle": shuffle
            ])
        } catch {
            self.logger.error("Play failed \(error)", displayCross: true)
        }
    }
    
    @MainActor
    func pause() async {
        do {
            _ = try await self.wsCommClient.request("/pause")
        } catch {
            self.logger.error("Pause failed \(error)", displayCross: true)
        }
    }
    
    @MainActor
    func stop() async {
        do {
            _ = try await self.wsCommClient.request("/stop")
        } catch {
            self.logger.error("Stop failed \(error)", displayCross: true)
        }
    }
    
    @MainActor
    func seekToTime(seconds: Int) async {
        do {
            _ = try await self.wsCommClient.request("/seek-to-time", body: [
                "seconds": seconds
            ])
        } catch {
            self.logger.error("Seek to time \(error)", displayCross: true)
        }
    }
    
    enum SkipType {
        case Previous, Next
    }
    
    @MainActor
    func skip(type: SkipType) async {
        do {
            _ = try await self.wsCommClient.request(type == .Previous ? "/previous" : "/next")
        } catch {
            self.logger.error("Skip failed \(error)", displayCross: true)
        }
    }
    
    @MainActor
    func reorderQueuedItem(from: Int, to: Int) async {
        self.queue.move(from: from, to: to)
        do {
            _ = try await self.wsCommClient.request("/reorder-queued-item", body: [
                "from": from,
                "to": to
            ])
        } catch {
            self.logger.error("Failed to reorder queued item from \(from) to \(to)", displayCross: true)
        }
    }
    
    @MainActor
    func openAirPlayPicker(x: Int? = nil, y: Int? = nil) async -> Bool {
        do {
            let result = try await self.wsCommClient.request("/open-airplay-picker", body: x != nil && y != nil ? [
                "x": x!,
                "y": y!
            ] : .none)
            return result["supportsAirPlay"].boolValue
        } catch {
            self.logger.error("Skip failed \(error)", displayCross: true)
        }
        
        return false
    }
    
    @MainActor
    func openInspector() async {
        if self.isReady {
            do {
                _ = try await self.wsCommClient.request("/open-inspector")
            } catch {
                self.logger.error("Failed to open CIderWebAgent's inspector", displayCross: true)
            }
        }
    }
    
    @MainActor
    func togglePlaybackSync() {
        Task {
            await (self.nowPlayingState.isPlaying ? self.pause() : self.play())
        }
    }
    
    @MainActor
    func setAudioQuality(_ quality: AudioQuality) async {
        do {
            _ = try await self.wsCommClient.request("/set-audio-quality", body: [
                "quality": quality.rawValue
            ])
        } catch {
            self.logger.error("Failed to set audio quality to \(quality.rawValue)", displayCross: true)
        }
    }
    
    @MainActor
    func setVolume(_ volume: Double) async {
        do {
            _ = try await self.wsCommClient.request("/set-volume", body: [
                "volume": volume
            ])
        } catch {
            self.logger.error("Failed to set volume to \(volume)", displayCross: true)
        }
    }
    
    func start() {
        if self.isRunning {
            return
        }
        
#if os(macOS)
        let connectWS = {
            self.wsCommClient.delegate = self
            self.logger.info("Attempting to connect to CiderPlaybackAgent WebSockets")
            self.wsCommClient.connect()
        }
        
        #if !DEBUG
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if Networking.isPortOpen(port: self.agentPort) {
                connectWS()
                timer.invalidate()
            }
        }
        #endif
        
        do {
            try self.proc.launch(outputHandler: { data in
                if !data.isEmpty {
                    guard let str = String(data: data, encoding: .utf8) else {
                        return
                    }
                    var newStr = str
                    if let last = newStr.last, last.isNewline {
                        newStr.removeLast()
                    }
                    
                    if newStr == "websocketcomm.ready" {
                        connectWS()
                    } else {
                        self.logger.info("[CiderPlaybackAgent] \(newStr)")
                    }
                }
            }, errorHandler: { data in
                guard let str = String(data: data, encoding: .utf8) else {
                    return
                }
                
                self.logger.error("CiderPlaybackAgent threw an error: \(str)")
            }, terminationHandler: { process in
                self.logger.error("CiderPlaybackAgent exited \(self.proc.terminationReason): \(self.proc.exitCode)")
            })
            self.isRunning = true
            self.logger.info("CiderPlaybackAgent on port \(self.agentPort) with Session ID \(self.agentSessionId)")
        } catch {
            self.logger.error("Error running CiderPlaybackAgent: \(error)")
        }
#endif
    }
    
    @MainActor
    func updateNowPlayingStateBeforeReady(item: MediaDynamic) {
        if item.id == self.nowPlayingState.item?.id {
            return
        }
        
        let (title, artistName, artwork, contentRating, Id): (String, String, MediaArtwork, String, String)
        switch item {
        case .mediaTrack(let mediaTrack):
            (title, artistName, artwork, contentRating, Id) = (mediaTrack.title, mediaTrack.artistName, mediaTrack.artwork, mediaTrack.contentRating, mediaTrack.id)
        case .mediaItem(let musicItem):
            (title, artistName, artwork, contentRating, Id) = (musicItem.title, musicItem.artistName, musicItem.artwork, musicItem.contentRating, musicItem.id)
        case .mediaPlaylist(let mediaPlaylist):
            (title, artistName, artwork, contentRating, Id) = (mediaPlaylist.title, mediaPlaylist.curatorName, mediaPlaylist.artwork, "", mediaPlaylist.id)
        }
        
        var artworkUrl: URL = artwork.getUrl(width: 200, height: 200)
        
        if artworkUrl.absoluteString.count > 256 || artworkUrl.absoluteString.contains("blobstore") {
            AF.request("https://api-rpc.cider.sh/", parameters: [
                "imageUrl": artworkUrl,
                "albumId": Id,
                "fileType": "jpg"
            ]).validate().responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let json = try JSON(data: data)
                        if let urlString = json["url"].string, let url = URL(string: urlString) {
                            artworkUrl = url
                        }
                    } catch {
                        self.logger.error("JSON Parsing Error: \(error)")
                    }
                case .failure(let error):
                    self.logger.error("Failed to fetch artwork: \(error)")
                }
                
#if os(macOS)
                DispatchQueue.global(qos: .default).async { [artworkUrl] in
                    self.discordRPCModal.agent.setActivityAssets(artworkUrl.absoluteString, title, "", "")
                    self.discordRPCModal.agent.setActivityState("by " + artistName)
                    self.discordRPCModal.agent.setActivityDetails(title)
                    self.discordRPCModal.agent.updateActivity()
                }
#endif
                
                self.nowPlayingState = NowPlayingState(
                    item: item,
                    name: title,
                    artistName: artistName,
                    contentRating: contentRating,
                    artworkURL: artworkUrl,
                    isPlaying: false,
                    isReady: false
                )
            }
            
        } else {
#if os(macOS)
            DispatchQueue.global(qos: .default).async { [artworkUrl] in
                self.discordRPCModal.agent.setActivityAssets(artworkUrl.absoluteString, title, "", "")
                self.discordRPCModal.agent.setActivityState("by " + artistName)
                self.discordRPCModal.agent.setActivityDetails(title)
                self.discordRPCModal.agent.updateActivity()
            }
#endif
            
            self.nowPlayingState = NowPlayingState(
                item: item,
                name: title,
                artistName: artistName,
                contentRating: contentRating,
                artworkURL: artworkUrl,
                isPlaying: false,
                isReady: false
            )
        }
        let artworkURL = artwork.getUrl(width: 200, height: 200)
#if os(macOS)
        DispatchQueue.global(qos: .default).async {
            self.discordRPCModal.agent.setActivityAssets(artworkURL.absoluteString, title, "", "")
            self.discordRPCModal.agent.setActivityState("by " + artistName)
            self.discordRPCModal.agent.setActivityDetails(title)
            self.discordRPCModal.agent.updateActivity()
        }
#endif
        self.nowPlayingState = NowPlayingState(
            item: item,
            name: title,
            artistName: artistName,
            contentRating: contentRating,
            artworkURL: artworkURL,
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
    
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
            
        case .connected:
            self.isReady = true
            self.logger.success("Connected to CiderPlaybackAgent", displayTick: true)
            break
            
        case .disconnected(let reason, let code):
            self.logger.error("CiderPlaybackAgent is disconnected with code \(code): \(reason)")
            break
            
        case .peerClosed:
            self.logger.error("WebSockets peer closed")
            
        case .error(let error):
            if let error = error {
                self.logger.error("WebSockets error: \(error.localizedDescription)")
            }
            break
            
        case .text(let message):
            guard let json = try? JSON(data: message.data(using: .utf8)!),
                  let eventName = json["eventName"].string,
                  let requestId = json["requestId"].string
            else { return }
            
            WSModal.shared.traffic.append(WSTrafficRecord(target: .CiderPlaybackAgent, rawJSONString: message, dateSent: .now, trafficType: .Receive, requestId: requestId))
            
            switch eventName {
                
            case "ciderPlaybackAgentReady":
                Task {
                    await self.setAutoPlay(self.playbackBehaviour.autoplayEnabled)
                    await self.setAudioQuality(Defaults[.audioQuality])
                }
                break
                
            case "mediaItemDidChange":
                withAnimation(.spring()) {
                    self.nowPlayingState.playbackPipelineInitialised = true
                }
                let mediaParams = json["mediaParams"]
                
                
                
                Task {
                    let id = mediaParams["id"].stringValue
                    guard let mediaTrack = try? await self.mkModal?.AM_API.fetchSong(id: id) else {
                        self.logger.error("Unable to fetch now playing track: \(id)")
                        return
                    }
                    
                    await self.updateNowPlayingStateBeforeReady(item: .mediaTrack(mediaTrack))
                    
                    DispatchQueue.main.async {
                        if let name = mediaParams["name"].string,
                           let contentRating = mediaParams["contentRating"].string,
                           let artistName = mediaParams["artistName"].string {
                            self.nowPlayingState.item = .mediaTrack(mediaTrack)
                            self.nowPlayingState.name = name
                            self.nowPlayingState.artistName = artistName
                            self.nowPlayingState.contentRating = contentRating
                        }
                        
                        let newArtworkURL = URL(string: mediaParams["artworkURL"].stringValue.replacingOccurrences(of: "{w}", with: "200").replacingOccurrences(of: "{h}", with: "200"))
                        if newArtworkURL != self.nowPlayingState.artworkURL {
                            self.nowPlayingState.artworkURL = newArtworkURL
                        }
                        
                        self.nowPlayingState.isPlaying = true
                        self.nowPlayingState.isReady = true
                    }
                }
                
                break
                
            case "playbackStateDidChange":
                switch json["playbackState"].string {
                    
                case "paused":
                    self.nowPlayingState.isPlaying = false
#if os(macOS)
                    DispatchQueue.global(qos: .default).async {
                        self.discordRPCModal.agent.setActivityTimestamps(0, 0)
                        self.discordRPCModal.agent.updateActivity()
                    }
#endif
                    break
                    
                case "stopped":
                    self.nowPlayingState.reset()
#if os(macOS)
                    DispatchQueue.global(qos: .default).async {
                        self.discordRPCModal.agent.clearActivity()
                    }
#endif
                    break
                    
                case "playing":
                    self.nowPlayingState.hasItemToPlay = true
                    self.nowPlayingState.isPlaying = true
                    self.nowPlayingState.isReady = true
                    break
                    
                default:
                    break
                    
                }
                break
                
            case "playbackTimeDidChange":
                Throttler.throttle(shouldRunImmediately: true) {
                    DispatchQueue.main.async {
                        let currentTime = TimeInterval(json["currentTime"].intValue + 1)
                        let remainingTime = TimeInterval(json["remainingTime"].intValue)
                        if self.appWindowModal.isFocused || self.appWindowModal.isVisibleInViewport {
                            self.nowPlayingState.currentTime = currentTime
                            self.nowPlayingState.remainingTime = remainingTime
                        }
                    }
                }
                break
                
            case "playbackDurationDidChange":
                DispatchQueue.main.async {
                    let timeInterval = TimeInterval(json["duration"].doubleValue)
                    if self.nowPlayingState.duration != timeInterval {
                        self.nowPlayingState.duration = timeInterval
                    }
                }
                break
                
            case "queueItemsDidChange":
                let newQueue = json["queue"]
                self.queue = []
                
                for (_, subJson):(String, JSON) in newQueue {
                    self.queue.append(MediaTrack(data: subJson))
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
