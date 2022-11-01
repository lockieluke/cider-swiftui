//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import WebKit

class MusicKitWorker {
    
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
        
        let wkWebView = WKWebView(frame: .zero, configuration: wkConfiguration)
        windowContainer.contentView?.addSubview(wkWebView)
        wkWebView.loadSimulatedRequest(URLRequest(url: URL(string: "https://beta.music.apple.com")!), responseHTML: self.bootstrapHTML)
        
        self.wkWebView = wkWebView
        self.windowContainer = windowContainer
        self.userToken = userToken
        self.developerToken = developerToken
    }
    
    func dispose() {
        let disposeSel: Selector = NSSelectorFromString("_killWebContentProcess")
        self.wkWebView.perform(disposeSel)
        self.windowContainer.close()
    }
    
}
