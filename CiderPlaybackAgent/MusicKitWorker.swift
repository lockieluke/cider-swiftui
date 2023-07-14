//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import WebKit
import SwiftyJSON

class MusicKitWorker : NSObject, WKScriptMessageHandler, WKNavigationDelegate, NSWindowDelegate {
    
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
    private let config: JSON
    private var callbacks: [String: ((_ eventName: String, _ dict: [String: AnyObject]) -> Void)] = [:]
    
    init(userToken: String, developerToken: String, config: JSON) {
        let userContentController = WKUserContentController().then {
            guard let jsPath = Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent("ciderplaybackagent.js"), let jsScript = try? String(contentsOfFile: jsPath.path, encoding: .utf8) else {
                fatalError("Unable to load CiderPlaybackAgent scripts")
            }
            let userScript = WKUserScript(source: "const AM_TOKEN=\"\(developerToken)\";const AM_USER_TOKEN=\"\(userToken)\";\(jsScript)", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            
            $0.addUserScript(userScript)
        }
        
        let wkConfiguration = WKWebViewConfiguration().then {
            $0.userContentController = userContentController
            $0.mediaTypesRequiringUserActionForPlayback = []
            $0.preferences.javaScriptCanOpenWindowsAutomatically = true
            $0.allowsAirPlayForMediaPlayback = true
    #if DEBUG
            $0.preferences.setValue(true, forKey: "developerExtrasEnabled")
    #endif
        }
        
        // Hack to enable playback for headless WKWebView
        let windowContainer = NSWindow(contentRect: NSRect(x: .zero, y: .zero, width: 1, height: 1), styleMask: [.borderless], backing: .buffered, defer: false).then {
            $0.animationBehavior = .none
            $0.collectionBehavior = .transient
        }
        
        let wkWebView = WKWebView(frame: .zero, configuration: wkConfiguration)
        windowContainer.contentView?.addSubview(wkWebView)
        
        defer {
            windowContainer.delegate = self
            wkWebView.navigationDelegate = self
            wkWebView.configuration.userContentController.add(self, name: "ciderkit")
            #if DEBUG
            wkWebView.loadSimulatedRequest(URLRequest(url: URL(string: "https://beta.music.apple.com")!), responseHTML: self.bootstrapHTML)
            #else
            wkWebView.load(URLRequest(url: URL(string: "https://beta.music.apple.com/stub")!))
            #endif
        }
        
        self.wkWebView = wkWebView
        self.windowContainer = windowContainer
        self.userToken = userToken
        self.developerToken = developerToken
        self.config = config
        
        super.init()
        self.setupMenus()
    }
    
    func setupMenus() {
        let menu = NSMenu()
        
        let undoManager = self.windowContainer.undoManager
        let editMenu = NSMenuItem().then {
            $0.submenu = NSMenu(title: "Edit")
            $0.submenu?.items = [
                NSMenuItem(title: undoManager?.undoMenuItemTitle ?? "Undo", action: Selector(("undo:")), keyEquivalent: "z"),
                NSMenuItem(title: undoManager?.redoMenuItemTitle ?? "Redo", action: Selector(("redo:")), keyEquivalent: "Z"),
                .separator(),
                NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"),
                NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"),
                NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"),
                NSMenuItem.separator(),
                NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)),
                           keyEquivalent: "a")
            ]
        }
        
        menu.items = [editMenu]
        NSApp.mainMenu = menu
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
    
    func skipToQueueIndex(_ index: Int) async {
        await self.asyncRunJS("window.ciderInterop.skipToQueueIndex(\(index))")
    }
    
    func setShuffleMode(_ shuffle: Bool) async {
        _ = try? await self.wkWebView.callAsyncJavaScript("window.ciderInterop.mk.shuffleMode = MusicKit.PlayerShuffleMode[\"\(shuffle ? "songs" : "off")\"]", contentWorld: .page)
    }
    
    func setRepeatMode(_ repeatMode: String) async {
        _ = try? await self.wkWebView.callAsyncJavaScript("window.ciderInterop.mk.repeatMode = MusicKit.PlayerRepeatMode[\"\(repeatMode)\"]", contentWorld: .page)
    }
    
    func setAutoPlay(_ autoPlay: Bool) async {
        _ = await self.asyncRunJS("window.ciderInterop.mk.autoplayEnabled = \(autoPlay)")
    }
    
    func openAirPlayPicker(x: Int? = nil, y: Int? = nil) async -> Bool {
        guard let supportsAirPlay = try? await self.wkWebView.callAsyncJavaScript("return window.ciderInterop.isAirPlayAvailable()", contentWorld: .page) as? Bool, supportsAirPlay else { return false }
        
        await NSApp.activate(ignoringOtherApps: true)
        await self.windowContainer.center()
        await self.windowContainer.makeKeyAndOrderFront(nil)
        if let x = x, let y = y {
            await self.windowContainer.setFrameOrigin(NSPoint(x: x, y: y))
        }
        await self.windowContainer.orderFrontRegardless()
        _ = await self.asyncRunJS("window.ciderInterop.openAirPlayPicker()")
        return true
    }
    
    func play() async {
        _ = try? await self.wkWebView.callAsyncJavaScript("return window.ciderInterop.play()", arguments: [:], contentWorld: .page)
    }
    
    func pause() async {
        await self.asyncRunMKJS("pause()")
    }
    
    func stop() async {
        await self.asyncRunMKJS("stop()")
    }
    
    func seekToTime(seconds: Int) async {
        _ = try? await self.wkWebView.callAsyncJavaScript("""
        let wasPlaying = window.ciderInterop.mk.isPlaying
        window.ciderInterop.mk.pause()
        await window.ciderInterop.mk.seekToTime(\(seconds))
        if (wasPlaying)
            await window.ciderInterop.mk.play()
        """, contentWorld: .page)
    }
    
    func previous() async {
        _ = await self.asyncRunJS("window.ciderInterop.previous()")
    }
    
    func next() async {
        _ = await self.asyncRunJS("window.ciderInterop.next()")
    }
    
    func setAudioQuality(audioQuality: Int) async {
        if audioQuality == 0 {
            // TODO: Handle lossless setting
        } else {
            await self.asyncRunJS("window.ciderInterop.mk.bitrate = \(audioQuality)")
        }
    }
    
    func setVolume(volume: Double) {
        self.syncRunMKJS("volume = \(volume)")
    }
    
    func reorderQueuedItem(from: Int, to: Int) async {
        _ = await self.asyncRunJS("window.ciderInterop.reorderQueue(\(from), \(to))")
    }
    
    private func asyncRunMKJS(_ script: String) async {
        do {
            _ = try await self.wkWebView.callAsyncJavaScript("return await window.ciderInterop.mk.\(script)", contentWorld: .page)
        } catch {
            print("Error running JavaScript: \(error)")
        }
    }
    
    private func syncRunMKJS(_ script: String) {
        self.wkWebView.evaluateJavaScript("window.ciderInterop.mk.\(script)")
    }
    
    @discardableResult
    private func asyncRunJS(_ script: String) async -> Any? {
        do {
            return try await self.wkWebView.evaluateJavaScriptAsync(script)
        } catch {
            print("Error running JavaScript: \(error)")
        }
        
        return nil
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
    
    func openInspectorInNewWindow() {
#if DEBUG
        if self.config["openWebInspectorAutomatically"].boolValue {
            if let inspector = self.wkWebView.value(forKey: "_inspector") as? AnyObject {
                _ = inspector.perform(Selector(("showConsole")))
            }
        }
#endif
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // hack to show WKInspector of the headless WKWebView without Safari
        self.openInspectorInNewWindow()
        
        self.callCallbacks("ciderPlaybackAgentReady", [:])
    }
    
}
