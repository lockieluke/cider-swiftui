//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import WebKit
import MediaPlayer

class MusicKitWorker : NSObject, WKScriptMessageHandler {
    
    private let wkWebView: WKWebView
    private let windowContainer: NSWindow
    private let bootstrapHTML = """
<!DocType html>
<head>
    <title>CiderPlaybackAgent</title>
</head>
<body>
    <p>\(Bundle.main.executableURL?.lastPathComponent ?? "Could not load process name")</p>
</body>
"""
    private let userToken: String
    private let developerToken: String
    private var callbacks: [String: ((_ eventName: String, _ dict: [String: AnyObject]) -> Void)] = [:]
    
    init(userToken: String, developerToken: String) {
        guard let jsPath = Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent("ciderplaybackagent.js"), let jsScript = try? String(contentsOfFile: jsPath.path, encoding: .utf8) else {
            fatalError("Unable to load CiderPlaybackAgent scripts")
        }
        
        let userScript = WKUserScript(source: "const AM_TOKEN=\"\(developerToken)\";const AM_USER_TOKEN=\"\(userToken)\";\(jsScript)", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let userContentController = WKUserContentController()
        userContentController.addUserScript(userScript)
        
        let wkConfiguration = WKWebViewConfiguration()
        wkConfiguration.userContentController = userContentController
        wkConfiguration.mediaTypesRequiringUserActionForPlayback = []
        wkConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        // Hack to enable playback for headless WKWebView
        let windowContainer = NSWindow(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel, .hudWindow], backing: .buffered, defer: false)
        windowContainer.animationBehavior = .none
        windowContainer.collectionBehavior = .transient
        
        let wkWebView = WKWebView(frame: .zero, configuration: wkConfiguration)
        windowContainer.contentView?.addSubview(wkWebView)
        defer {
            wkWebView.configuration.userContentController.add(self, name: "ciderkit")
            wkWebView.loadSimulatedRequest(URLRequest(url: URL(string: "https://beta.music.apple.com")!), responseHTML: self.bootstrapHTML)
        }
        
        self.wkWebView = wkWebView
        self.windowContainer = windowContainer
        self.userToken = userToken
        self.developerToken = developerToken
        
        super.init()
    }
    
    func addCallback(uuid: String = UUID().uuidString, _ callback: @escaping (_ eventName: String, _ dict: [String: AnyObject]) -> Void) {
        self.callbacks[uuid] = callback
    }
    
    func removeCallback(uuid: String) {
        self.callbacks.removeValue(forKey: uuid)
    }
    
    func callCallbacks(_ eventName: String, _ dict: [String: AnyObject]) {
        callbacks.forEach { item in
            let (_, callback) = item
            callback(eventName, dict)
        }
    }
    
    func setQueueWithAlbumID(albumID: String) async {
        _ = try? await self.wkWebView.callAsyncJavaScript("return window.ciderInterop.setQueue({album: albumId})", arguments: ["albumId": albumID], contentWorld: .page)
    }
    
    func setQueueWithPlaylistID(playlistID: String) async {
        _ = try? await self.wkWebView.callAsyncJavaScript("return window.ciderInterop.setQueue({playlist: playlistId})", arguments: ["playlistId": playlistID], contentWorld: .page)
    }
    
    func setQueueWithSongID(songID: String) async {
        _ = try? await self.wkWebView.callAsyncJavaScript("return window.ciderInterop.setQueue({song: songId})", arguments: ["songId": songID], contentWorld: .page)
    }
    
    func setShuffleMode(_ shuffle: Bool) async {
        _ = try? await self.wkWebView.callAsyncJavaScript("return window.ciderInterop.mk.shuffleMode = \(shuffle ? 1 : 0)", contentWorld: .page)
    }
    
    func play() async {
        _ = try? await self.wkWebView.callAsyncJavaScript("return window.ciderInterop.play()", arguments: [:], contentWorld: .page)
    }
    
    private func asyncRunMKJS(_ script: String) async {
        do {
            _ = try await self.wkWebView.evaluateJavaScriptAsync("window.ciderInterop.mk.\(script)")
        } catch {
            print("Error running JavaScript: \(error)")
        }
    }
    
    private func asyncRunJS(_ script: String) async {
        do {
            _ = try await self.wkWebView.evaluateJavaScriptAsync(script)
        } catch {
            print("Error running JavaScript: \(error)")
        }
    }
    
    func dispose() {
        let disposeSel: Selector = NSSelectorFromString("_killWebContentProcess")
        self.wkWebView.perform(disposeSel)
        self.windowContainer.close()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
            
        case "ciderkit":
            guard let dict = message.body as? [String: AnyObject] else { return }
            guard let eventName = dict["event"] as? String else { return }
            
            self.callCallbacks(eventName, dict)
            break
            
        default:
            break
        }
    }
    
}

extension MusicKitWorker : NSWindowDelegate {
    
    func windowDidBecomeKey(_ notification: Notification) {
        
    }
    
}
