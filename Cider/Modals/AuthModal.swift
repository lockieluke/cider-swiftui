//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import WebKit
import SwiftUI
import SwiftyJSON

#if canImport(AppKit)
import AppKit
class AuthModal: ObservableObject {
    
    private let logger: Logger
    private var wkWebView: WKWebView?
    private let authWindow: NSWindow
    private var wkUIDelegate: AuthModalUIDelegate?
    private var wkNavDelegate: AuthModalNavigationDelegate?
    
    private let appWindowModal: AppWindowModal
    private let mkModal: MKModal
    private let cacheModel: CacheModal
    
    private static let INITIAL_URL = URLRequest(url: URL(string: "https://www.apple.com/legal/privacy/en-ww/cookies/")!)
    private static let USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_5_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.6 Safari/605.1.15"
    
    private static let IS_FORGETTING_AUTH: Bool = CommandLine.arguments.contains("-clear-auth")
    private static let IS_PASSING_LOGS: Bool = CommandLine.arguments.contains("-pass-auth-logs")
    
    var authenticatingCallback: ((_ userToken: String) -> Void)?
    
    class AuthModalNavigationDelegate : NSObject, WKNavigationDelegate {
        
        weak var parent: AuthModal! = nil
        
        init(parent: AuthModal) {
            self.parent = parent
        }
        
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            parent.logger.error("AuthModal terminated")
        }
        
    }
    
    class AuthModalUIDelegate : NSObject, WKUIDelegate {
        
        weak var parent: AuthModal! = nil
        
        init(parent: AuthModal) {
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
            
            if AuthModal.IS_PASSING_LOGS {
                if let rawJson = json.rawString() {
                    parent.logger.info("JSON message from AuthModal: \(rawJson)")
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
    
    init(mkModal: MKModal, appWindowModal: AppWindowModal, cacheModel: CacheModal) {
        if AuthModal.IS_FORGETTING_AUTH {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                await AuthModal.clearAuthCache()
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + .milliseconds(300))
        }
        
        self.wkWebView = WKWebView(frame: .zero).then {
            #if DEBUG
            $0.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
            #endif
            $0.customUserAgent = AuthModal.USER_AGENT
        }
        
        self.authWindow = NSWindow(contentRect: NSRect(x: .zero, y: .zero, width: 800, height: 600), styleMask: [.closable, .titled], backing: .buffered, defer: false).then {
            $0.title = "Sign In - \(Bundle.main.displayName)"
            $0.isMovable = false
            $0.isMovableByWindowBackground = false
        }
        
        self.mkModal = mkModal
        self.appWindowModal = appWindowModal
        self.cacheModel = cacheModel
        
        self.logger = Logger(label: "AuthModal")

        self.wkUIDelegate = AuthModalUIDelegate(parent: self)
        wkWebView?.uiDelegate = wkUIDelegate
        
        self.wkNavDelegate = AuthModalNavigationDelegate(parent: self)
        wkWebView?.navigationDelegate = wkNavDelegate
    }
    
    func retrieveUserToken() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                let developerToken = try await self.mkModal.fetchDeveloperToken()
                
                if let lastAmUserToken = try? self.cacheModel.storage?.object(forKey: "last_am_usertoken"), await self.mkModal.AM_API.validateUserToken(lastAmUserToken) {
                    self.logger.success("Logged in with previously cached user token", displayTick: true)
                    continuation.resume(returning: lastAmUserToken)
                    return
                }
                
                guard let jsPath = Bundle.main.sharedSupportURL?.appendingPathComponent("ciderwebauth.js"),
                      let script = try? String(contentsOfFile: jsPath.path, encoding: .utf8) else {
                    fatalError("Unable to load CiderWebAuth Scripts")
                }
                
                DispatchQueue.main.async {
                    let userScript = WKUserScript(source: """
                                                  const initialURL = \"\(AuthModal.INITIAL_URL)\";
                                                  const amToken = \"\(developerToken)\";
                                                  const isForgettingAuth = \(AuthModal.IS_FORGETTING_AUTH);
                                                  \(script)
                                                  """, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
                    self.wkWebView?.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
                    self.wkWebView?.configuration.userContentController.addUserScript(userScript)
                    
                    if self.mkModal.isAuthorised , let userToken = self.mkModal.AM_API.AM_USER_TOKEN {
                        self.logger.success("Logged in with previously fetched user token", displayTick: true)
                        continuation.resume(returning: userToken)
                    }
                    
                    self.authenticatingCallback = { userToken in
                        do {
                            try self.cacheModel.storage?.setObject(userToken, forKey: "last_am_usertoken", expiry: .date(Date().addingTimeInterval(7 * 60 * 60)))
                        } catch {
                            self.logger.error("Failed to cache Apple Music user token: \(error)")
                        }
                        continuation.resume(returning: userToken)
                        self.wkWebView?.load(URLRequest(url: URL(string: "about:blank")!))
                        
                        // hack to dispose wkwebview manually
            //            let disposeSel: Selector = NSSelectorFromString("_killWebContentProcess")
            //            self.wkWebView?.perform(disposeSel)
                        
                        self.wkWebView?.removeFromSuperview()
                        self.authWindow.close()
                        
                        self.wkWebView = nil
                    }
                    
                    // loadSimulatedRequest for some reason doesn't not work in sandbox mode
                    #if DEBUG
                    self.wkWebView?.loadSimulatedRequest(AuthModal.INITIAL_URL, responseHTML: "<p>CiderWebAuth</p>")
                    #else
                    // go to /stub so it doesn't load all the images in Apple Music Web's homepage
                    self.wkWebView?.load(URLRequest(url: URL(string: "https://music.apple.com/stub")!))
                    #endif
                }
            }
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
#endif
