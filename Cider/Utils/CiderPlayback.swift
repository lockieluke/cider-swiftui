//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import Foundation
import Defaults
import Alamofire

enum PlaybackEngineType: String, Defaults.Serializable {
    case MKJS = "musickit-js"
}

class PlaybackEngineBaseClass {
    
    weak var parent: CiderPlayback!
    
    init(parent: CiderPlayback) {
        self.parent = parent
    }
    
}

protocol PlaybackEngine: PlaybackEngineBaseClass {
    
    func setQueue(item: MediaDynamic) async
    func skipToQueueIndex(_ index: Int) async
    func reorderQueuedItem(from: Int, to: Int) async
    func setShuffleMode(_ shuffle: Bool) async
    func setRepeatMode(_ repeatMode: RepeatMode) async
    func setAutoPlay(_ autoPlay: Bool) async
    func play(shuffle: Bool) async
    func pause() async
    func stop() async
    func seekToTime(seconds: Int) async
    
    func skip(_ type: CiderPlayback.SkipType) async
    
    func openAirPlayPicker(x: Int, y: Int) async
    func openDebugPanel() async
    func setAudioQuality(_ quality: AudioQuality) async
    func setVolume(_ volume: Double) async
    
    func start() async
    func shutdown()
    
}

extension PlaybackEngine {
    
    func play() async {
        await self.play(shuffle: false)
    }
    
}

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

class CiderPlayback : ObservableObject {
    
    @Published var nowPlayingState = NowPlayingState()
    @Published var playbackBehaviour = PlaybackBehaviour()

    let logger = Logger(label: "CiderPlayback")
    private let appWindowModal: AppWindowModal
    var userToken: String?
    var developerToken: String?
    private var defaultsObserver: Defaults.Observation!
    
    let mkModal: MKModal
    var queue: [MediaTrack] = []
    var playbackEngine: (any PlaybackEngine)!
    
    init(appWindowModal: AppWindowModal, mkModal: MKModal) {
        self.appWindowModal = appWindowModal
        self.mkModal = mkModal
        self.playbackEngine = self.getEngine(type: Defaults[.playbackBackend])
        
        defer {
            self.defaultsObserver = Defaults.observe(.playbackBackend) { changes in
                self.playbackEngine = self.getEngine(type: Defaults[.playbackBackend])
            }
        }
    }
    
    func setDeveloperToken(developerToken: String) async {
        self.developerToken = developerToken
        await self.start()
    }
    
    func setUserToken(userToken: String) async {
        self.userToken = userToken
        await self.start()
    }
    
    func start() async {
        await self.playbackEngine.start()
    }
    
    func shutdown() {
        self.playbackEngine.shutdown()
    }
    
    @MainActor
    func updateNowPlayingStateBeforeReady(item: MediaDynamic) {
        if item.id == self.nowPlayingState.item?.id {
            return
        }
        
        let (title, artistName, artwork, contentRating, Id): (String, String, MediaArtwork, String, String) = (item.title, item.artistName, item.artwork, item.contentRating, item.id)
        
        var artworkUrl: URL = artwork.getUrl(width: 200, height: 200)
        
        if artworkUrl.absoluteString.count > 256 || artworkUrl.absoluteString.contains("blobstore") {
            struct RPCResponse: Decodable {
                let url: String
            }
            
            AF.request("https://api-rpc.cider.sh/", parameters: [
                "imageUrl": artworkUrl,
                "albumId": Id,
                "fileType": "jpg"
            ]).validate().responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let json = try JSONDecoder().decode(RPCResponse.self, from: data)
                        artworkUrl = URL(string: json.url)!
                    } catch {
                        self.logger.error("JSON Parsing Error: \(error.localizedDescription)")
                    }
                case .failure(let error):
                    self.logger.error("Failed to fetch artwork: \(error.localizedDescription)")
                }
                
#if os(macOS)
                ElevationHelper.shared.xpc.rpcSetActivityAssets(largeImage: artworkUrl.absoluteString, largeText: title, smallImage: "", smallText: "")
                ElevationHelper.shared.xpc.rpcSetActivityState(state: "by \(artistName)")
                ElevationHelper.shared.xpc.rpcSetActivityDetails(details: title)
                ElevationHelper.shared.xpc.rpcUpdateActivity()
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
            ElevationHelper.shared.xpc.rpcSetActivityAssets(largeImage: artworkUrl.absoluteString, largeText: title, smallImage: "", smallText: "")
            ElevationHelper.shared.xpc.rpcSetActivityState(state: "by \(artistName)")
            ElevationHelper.shared.xpc.rpcSetActivityDetails(details: title)
            ElevationHelper.shared.xpc.rpcUpdateActivity()
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
        ElevationHelper.shared.xpc.rpcSetActivityAssets(largeImage: artworkUrl.absoluteString, largeText: title, smallImage: "", smallText: "")
        ElevationHelper.shared.xpc.rpcSetActivityState(state: "by \(artistName)")
        ElevationHelper.shared.xpc.rpcSetActivityDetails(details: title)
        ElevationHelper.shared.xpc.rpcUpdateActivity()
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
    
    private func getEngine(type: PlaybackEngineType) -> any PlaybackEngine {
        switch type {
        case .MKJS:
            return MKJSPlayback(parent: self)
        }
    }
    
    func clearAndPlay(shuffle: Bool = false) async {
        await self.playbackEngine.stop()
        await self.playbackEngine.play(shuffle: shuffle)
    }
    
    func togglePlaybackSync() {
        Task {
            await (self.nowPlayingState.isPlaying ? self.playbackEngine.pause() : self.playbackEngine.play())
        }
    }

    enum SkipType {
        case Previous, Next
    }
    
}
