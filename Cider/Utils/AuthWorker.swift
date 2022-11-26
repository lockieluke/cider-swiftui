//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import WebKit
import SwiftUI
import SwiftyJSON

final class AuthWorker {
    
    private let logger: Logger
    private var wkWebView: WKWebView?
    private let authWindow: NSWindow
    private var wkUIDelegate: AuthWorkerUIDelegate?
    
    private let appWindowModal: AppWindowModal
    private let mkModal: MKModal
    
    private static let INITIAL_URL = URLRequest(url: URL(string: "https://www.apple.com/legal/privacy/en-ww/cookies/")!)
    private static let USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_5_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.6 Safari/605.1.15"
    
    private static let IS_FORGETTING_AUTH: Bool = CommandLine.arguments.contains("-clear-auth")
    private static let IS_PASSING_LOGS: Bool = CommandLine.arguments.contains("-pass-auth-logs")
    
    var authenticatingCallback: ((_ userToken: String) -> Void)?
    
    class AuthWorkerUIDelegate : NSObject, WKUIDelegate {
        
        weak var parent: AuthWorker! = nil
        
        init(parent: AuthWorker) {
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
            
            if AuthWorker.IS_PASSING_LOGS {
                if let rawJson = json.rawString() {
                    parent.logger.info("JSON message from AuthWorker: \(rawJson)")
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
                fatalError("Error occurred when authenticating AM User: \(json["message"].string ?? "No error description")")
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
    
    init(mkModal: MKModal, appWindowModal: AppWindowModal) {
        if AuthWorker.IS_FORGETTING_AUTH {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                await AuthWorker.clearAuthCache()
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + .milliseconds(300))
        }
        
        self.wkWebView = WKWebView(frame: .zero)
        wkWebView?.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        wkWebView?.customUserAgent = AuthWorker.USER_AGENT
        
        self.authWindow = NSWindow(contentRect: NSRect(x: .zero, y: .zero, width: 800, height: 600), styleMask: [.closable, .titled], backing: .buffered, defer: false)
        if let displayName = Bundle.main.displayName {
            authWindow.title = "Sign In - \(displayName)"
        }
        authWindow.isMovable = false
        authWindow.isMovableByWindowBackground = false
        
        self.mkModal = mkModal
        self.appWindowModal = appWindowModal
        
        self.logger = Logger(label: "AuthWorker")

        self.wkUIDelegate = AuthWorkerUIDelegate(parent: self)
        wkWebView?.uiDelegate = wkUIDelegate
        
        Task {
            
        }
    }
    
    func presentAuthView(authenticatingCallback: ((_ userToken: String) -> Void)? = nil) async {
        guard let jsPath = Bundle.main.sharedSupportURL?.appendingPathComponent("ciderwebauth.js"),
              let script = try? String(contentsOfFile: jsPath.path, encoding: .utf8) else {
            fatalError("Unable to load CiderWebAuth Scripts")
        }
        
        let developerToken = await self.mkModal.authorise()
        
        DispatchQueue.main.async {
            let userScript = WKUserScript(source: """
                                          const initialURL = \"\(AuthWorker.INITIAL_URL)\";
                                          const amToken = \"\(developerToken)\";
                                          const isForgettingAuth = \(AuthWorker.IS_FORGETTING_AUTH);
                                          \(script)
                                          """, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            self.wkWebView?.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
            self.wkWebView?.configuration.userContentController.addUserScript(userScript)
            
            if self.mkModal.isAuthorised {
                self.logger.success("Logged in with previously fetched user token", displayTick: true)
                return
            }
            
            self.logger.info("Presenting AuthWindow")
            self.authenticatingCallback = { userToken in
                self.wkWebView?.load(URLRequest(url: URL(string: "about:blank")!))
                
                // hack to dispose wkwebview manually
    //            let disposeSel: Selector = NSSelectorFromString("_killWebContentProcess")
    //            self.wkWebView?.perform(disposeSel)
                
                self.wkWebView?.removeFromSuperview()
                self.authWindow.close()
                
                self.wkWebView = nil
                authenticatingCallback?(userToken)
            }
            
            self.wkWebView?.loadSimulatedRequest(AuthWorker.INITIAL_URL, responseHTML: "<p>Cider AuthWorker</p>")
        }
    }
    
    func showAuthWindow() {
        guard let wkWebView = wkWebView else { return }
        wkWebView.frame.size = (authWindow.contentView?.frame.size)!
        wkWebView.autoresizingMask = [.height, .width]
        authWindow.contentView?.addSubview(wkWebView)
        
        _ = self.appWindowModal.$nsWindow.sink(receiveValue: { parentWindow in
            let parentWindow = parentWindow.unsafelyUnwrapped
            parentWindow.addChildWindow(self.authWindow, ordered: .above)
            self.authWindow.center()
            self.authWindow.makeKeyAndOrderFront(nil)
        })
    }
    
    static func clearAuthCache() async {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                WKWebsiteDataStore.default().removeData(ofTypes: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache], modifiedSince: Date(timeIntervalSince1970: 0)) {
                    // TODO: better way to handle signout
                    Logger.shared.info("Successfully cleared auth cache")
                    continuation.resume()
                }
            }
        }
    }
    
}
