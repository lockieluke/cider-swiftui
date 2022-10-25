//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import WebKit

class MusicKitWorker {
    
    private let wkWebView: WKWebView
    private let bootstrapHTML = """
<!DocType html>
<head>
    <title>CiderPlaybackAgent</title>
</head>
<body>
    <p>\(Bundle.main.executableURL?.lastPathComponent ?? "Could not load process name")</p>
</body>
"""
    
    init() {
        guard let jsPath = Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent("ciderplaybackagent.js"), let jsScript = try? String(contentsOfFile: jsPath.path, encoding: .utf8) else {
            fatalError("Unable to load CiderPlaybackAgent scripts")
        }
        
        let userScript = WKUserScript(source: jsScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let userContentController = WKUserContentController()
        userContentController.addUserScript(userScript)
        
        let wkConfiguration = WKWebViewConfiguration()
        wkConfiguration.userContentController = userContentController
        wkConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        let wkWebView = WKWebView(frame: .zero, configuration: wkConfiguration)
        wkWebView.loadSimulatedRequest(URLRequest(url: URL(string: "https://beta.music.apple.com")!), responseHTML: self.bootstrapHTML)
        
        self.wkWebView = wkWebView
    }
    
    func dispose() {
        let disposeSel: Selector = NSSelectorFromString("_killWebContentProcess")
        self.wkWebView.perform(disposeSel)
    }
    
}
