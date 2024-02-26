//
//  MKJSPlayback.swift
//  Cider
//
//  Created by Sherlock LUK on 21/02/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import Foundation
import WebKit
import SwiftHtml
import Defaults
import Throttler
import SwiftyJSON

class MKJSPlayback: PlaybackEngineBaseClass, PlaybackEngine {
    
    private weak var logger: Logger! {
        return self.parent.logger
    }
    
    var webview: WKWebView!
    private var scriptHandler: MKJSScriptMessageHandler?
    
    class MKJSScriptMessageHandler: NSObject, WKScriptMessageHandler {
        
        private weak var parent: MKJSPlayback! = nil
        
        init(parent: MKJSPlayback) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "ciderkit" {
                guard let dict = message.body as? [String: AnyObject] else { return }
                guard let eventName = dict["event"] as? String else { return }
                
                if eventName == "error", let message = dict["message"] {
                    self.parent.logger.error("\(String(describing: message))")
                } else if eventName == "mediaItemDidChange", let id = dict["id"] {
                    self.parent.parent.nowPlayingState.playbackPipelineInitialised = true
                    
                    Task {
                        do {
                            let track = try await self.parent.parent.mkModal.AM_API.fetchSong(id: String(describing: id))
                            await self.parent.parent.updateNowPlayingStateBeforeReady(item: .mediaTrack(track))
                        } catch {
                            self.parent.logger.error("Error fetching song upon media change: \(error.localizedDescription)")
                        }
                    }
                    
                    self.parent.parent.nowPlayingState.isPlaying = true
                    self.parent.parent.nowPlayingState.isReady = true
                } else if eventName == "playbackStateDidChange", let playbackState = dict["playbackState"] as? String {
                    switch playbackState {
                        
                    case "paused":
                        self.parent.parent.nowPlayingState.isPlaying = false
#if os(macOS)
                        Task {
                            await ElevationHelper.shared.rpcSetActivityTimestamps(start: 0, end: 0)
                            await ElevationHelper.shared.rpcUpdateActivity()
                        }
#endif
                        break
                        
                    case "stopped":
                        self.parent.parent.nowPlayingState.reset()
#if os(macOS)
                        Task {
                            await ElevationHelper.shared.rpcClearActivity()
                        }
#endif
                        break
                        
                    case "playing":
                        self.parent.parent.nowPlayingState.hasItemToPlay = true
                        self.parent.parent.nowPlayingState.isPlaying = true
                        self.parent.parent.nowPlayingState.isReady = true
                        break
                        
                    default:
                        break
                        
                    }
                } else if eventName == "playbackTimeDidChange", let currentTime = dict["currentTime"] as? Int, let remainingTime = dict["remainingTime"] as? Int {
                    if self.parent.parent.appWindowModal.isVisibleInViewport {
                        let currentTime = TimeInterval(currentTime + 1)
                        let remainingTime = TimeInterval(remainingTime)
                        
                        self.parent.parent.nowPlayingState.currentTime = currentTime
                        self.parent.parent.nowPlayingState.remainingTime = remainingTime
                    }
                } else if eventName == "playbackDurationDidChange", let duration = dict["duration"] as? Double, duration != .zero {
                    print("duration: \(duration)")
                    let timeInterval = TimeInterval(duration)
                    if self.parent.parent.nowPlayingState.duration != timeInterval {
                        self.parent.parent.nowPlayingState.duration = timeInterval
                    }
                } else if eventName == "queueItemsDidChange", let _items = dict["items"] {
                    let items = JSON(_items)
                    self.parent.parent.queue = []
                    
                    for (_, subJson):(String, JSON) in items {
                        self.parent.parent.queue.append(MediaTrack(data: subJson))
                    }
                }
            }
        }
        
    }
    
    func setQueue(item: MediaDynamic) async {
        await self.runMKJS("setQueue({\(item.singularType): id})", arguments: ["id": item.singularType == "album" ? item.albumId! : item.id], async: true)
    }
    
    func skipToQueueIndex(_ index: Int) async {
        await self.runMKJS("skipToQueueIndex(index)", arguments: ["index": index])
    }
    
    func reorderQueuedItem(from: Int, to: Int) async {
        await self.runMKJS("reorderQueue(from, to)", arguments: ["from": from, "to": to])
    }
    
    func setShuffleMode(_ shuffle: Bool) async {
        await self.runMKJS("mk.shuffleMode = MusicKit.PlayerShuffleMode[\"\(shuffle ? "songs" : "off")\"]", isAssignment: true)
    }
    
    func setRepeatMode(_ repeatMode: RepeatMode) async {
        await self.runMKJS("mk.repeatMode = MusicKit.PlayerRepeatMode[\"\(repeatMode)\"]", isAssignment: true)
    }
    
    func setAutoPlay(_ autoPlay: Bool) async {
        DispatchQueue.main.async {
            self.parent.playbackBehaviour.autoplayEnabled = autoPlay
        }
        await self.runMKJS("setAutoplay(autoplay)", arguments: ["autoplay": autoPlay], isAssignment: true)
    }
    
    func play(shuffle: Bool) async {
        await self.runMKJS("play()", async: true)
    }
    
    func pause() async {
        await self.runMKJS("mk.pause()")
    }
    
    func stop() async {
        await self.runMKJS("mk.stop()")
    }
    
    func seekToTime(seconds: Int) async {
        await self.runMKJS("seekToTime(seconds)", arguments: ["seconds": seconds], async: true)
    }
    
    func skip(_ type: CiderPlayback.SkipType) async {
        if type == .Next {
            await self.runMKJS("next()")
        }
        
        if type == .Previous {
            await self.runMKJS("previous()")
        }
    }
    
    func openAirPlayPicker(x: Int, y: Int) async {
        await self.runMKJS("openAirPlayPicker()")
    }
    
    func openDebugPanel() async {
        #if DEBUG
        DispatchQueue.main.async {
            if let inspector = self.webview.value(forKey: "_inspector") as? AnyObject {
                _ = inspector.perform(Selector(("showConsole")))
            }
        }
        #endif
    }
    
    func setAudioQuality(_ quality: AudioQuality) async {
        await self.runMKJS("mk.bitrate = \(quality.rawValue)", isAssignment: true)
    }
    
    func setVolume(_ volume: Double) async {
        await self.runMKJS("mk.volume = \(volume.clamped(to: 0...1))", isAssignment: true)
    }
    
    func start() async {
        guard let userToken = self.parent.userToken, let developerToken = self.parent.developerToken else { return }
        
        DispatchQueue.main.async {
            let mkjsScriptMessageHandler = MKJSScriptMessageHandler(parent: self)
            self.webview = WKWebView(frame: .zero).then {
#if DEBUG
                $0.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
#endif
                $0.configuration.userContentController.add(mkjsScriptMessageHandler, name: "ciderkit")
                $0.configuration.mediaTypesRequiringUserActionForPlayback = []
                $0.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
                $0.configuration.allowsAirPlayForMediaPlayback = true
            }
            
            
            let doc = Document(.html) {
                Html {
                    Head {
                        Title("MKJSPlayback")
                        
                        Meta().charset("utf-8")
                        Meta().name(.viewport).content("width=device-width, initial-scale=1")
                        
                        Script().setContents("const AM_TOKEN=\"\(developerToken)\";const AM_USER_TOKEN=\"\(userToken)\";const DEFAULT_AUDIO_QUALITY=\(Defaults[.audioQuality].rawValue);const DEFAULT_AUTOPLAY=\(self.parent.playbackBehaviour.autoplayEnabled);\(precompileIncludeStr("@/CiderWebModules/dist/mkjs-playback.js"))")
                    }
                    Body {
                        H1("MKJSPlayback")
                    }
                }
            }
            let html = DocumentRenderer(minify: true).render(doc)
            
            self.scriptHandler = mkjsScriptMessageHandler
            self.webview.loadHTMLString(html, baseURL: URL(string: "https://beta.music.apple.com")!)
        }
        
#if DEBUG
        if Defaults[.debugOpenWebInspectorAutomatically] {
            await self.openDebugPanel()
        }
#endif
    }
    
    private func runMKJS(_ script: String, arguments: [String: Any] = [:], async: Bool = false, isAssignment: Bool = false) async {
        do {
            _ = try await self.webview.callAsyncJavaScript("\(isAssignment ? "" : "return ")\(async ? "await " : "")window.ciderInterop.\(script)", arguments: arguments, contentWorld: .page)
        } catch {
            self.logger.error("Failed to run MKJS sync command: \(error.localizedDescription)")
        }
    }
    
    func shutdown() {
        // Private API usage
        if !self.webview.isNil {
            let disposeSel: Selector = NSSelectorFromString("_killWebContentProcess")
            self.webview.perform(disposeSel)
        }
    }
    
}
