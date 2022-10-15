//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import WebKit
import SwiftUI
import SwiftyJSON

final class AuthWorkerView {
    
    private let wkWebView: WKWebView
    private let authWindow: NSWindow
    private var wkUIDelegate: AuthWorkerUIDelegate?
    
    static let shared = AuthWorkerView()
    private static let INITIAL_URL = URLRequest(url: URL(string: "https://www.apple.com/legal/privacy/en-ww/cookies/")!)
    private static let USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_5_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.6 Safari/605.1.15"
    
    private static let IS_FORGETTING_AUTH: Bool = CommandLine.arguments.contains("-clear-auth")
    private static let IS_PASSING_LOGS: Bool = CommandLine.arguments.contains("-pass-auth-logs")
    
    public var authenticatingCallback: ((_ userToken: String) -> Void)?
    
    class AuthWorkerUIDelegate : NSObject, WKUIDelegate {
        
        weak var parent: AuthWorkerView! = nil
        
        init(parent: AuthWorkerView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            // handling sendNativeMessage
            
            guard let messageData = message.data(using: .utf8) else {
                completionHandler()
                return
            }
            guard let json = try? JSON(data: messageData) else {
                completionHandler()
                return
            }
            
            if AuthWorkerView.IS_PASSING_LOGS {
                if let rawJson = json.rawString() {
                 print("JSON message from AuthWorker: \(rawJson)")
                }
            }
            
            if let action = json["action"].string {
                switch action {
                    
                case "authenticated":
                    let token = json["token"].stringValue
                    parent.authenticatingCallback?(token)
                    break
                    
                case "authenticating-apple-id":
                    parent.showAuthWindow()
                    break
                    
                default:
                    break
                    
                }
            }
            
            if json["error"].exists() {
                fatalError("Error occurred when authenticating AM User: \(json["error"]["message"].string ?? "No error description")")
            }
            
            completionHandler()
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            let request = navigationAction.request
            if let url = navigationAction.request.url {
                if url.absoluteString.contains("apple.com") {
                    webView.load(request)
                }
            }
            return nil
        }
        
    }
    
    init() {
        if AuthWorkerView.IS_FORGETTING_AUTH {
            AuthWorkerView.clearAuthCache()
        }
        
        guard let jsPath = Bundle.main.path(forResource: "ciderwebauth", ofType: "js"),
              let script = try? String(contentsOfFile: jsPath, encoding: .utf8) else {
            fatalError("Unable to load CiderWebAuth Scripts")
        }
        
        let userScript = WKUserScript(source: """
                                      const initialURL = \"\(AuthWorkerView.INITIAL_URL)\";
                                      const amToken = \"\(MKModal.shared.AM_API.SAFE_AM_TOKEN)\";
                                      const isForgettingAuth = \(AuthWorkerView.IS_FORGETTING_AUTH);
                                      \(script)
                                      """, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let userContentController = WKUserContentController()
        userContentController.addUserScript(userScript)
        
        let wkConfiguration = WKWebViewConfiguration()
        wkConfiguration.userContentController = userContentController
        wkConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        self.wkWebView = WKWebView(frame: .zero, configuration: wkConfiguration)
        wkWebView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        wkWebView.customUserAgent = AuthWorkerView.USER_AGENT
        
        self.authWindow = NSWindow(contentRect: NSRect(x: .zero, y: .zero, width: 800, height: 600), styleMask: [.closable, .titled], backing: .buffered, defer: false)
        if let displayName = Bundle.main.displayName {
            authWindow.title = "Sign In - \(displayName)"
        }
        authWindow.isMovable = false
        authWindow.isMovableByWindowBackground = false

        self.wkUIDelegate = AuthWorkerUIDelegate(parent: self)
        wkWebView.uiDelegate = wkUIDelegate
    }
    
    func presentAuthView(authenticatingCallback: ((_ userToken: String) -> Void)? = nil) {
        print("Presenting AuthWindow")
        self.authenticatingCallback = { [authWindow, wkWebView] userToken in
            authWindow.close()
            wkWebView.load(URLRequest(url: URL(string: "about:blank")!))
            authenticatingCallback?(userToken)
        }
        
        wkWebView.load(AuthWorkerView.INITIAL_URL)
    }
    
    func showAuthWindow() {
        wkWebView.frame.size = (authWindow.contentView?.frame.size)!
        wkWebView.autoresizingMask = [.height, .width]
        authWindow.contentView?.addSubview(wkWebView)
        
        if let parentWindow = AppWindowModal.shared.nsWindow {
            parentWindow.addChildWindow(authWindow, ordered: .above)
        }
        
        authWindow.center()
        authWindow.makeKeyAndOrderFront(nil)
    }
    
    func signOut(completion: (() -> Void)? = nil) {
        self.wkWebView.evaluateJavaScript("window.authoriseAM();") { any, error in
            completion?()
        }
    }
    
    static func clearAuthCache() {
        WKWebsiteDataStore.default().removeData(ofTypes: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache], modifiedSince: Date(timeIntervalSince1970: 0)) {
            print("Successfully cleared auth cache")
        }
    }
    
}
