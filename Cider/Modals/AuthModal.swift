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
    private static let IS_PASSING_LOGS: Bool = CommandLine.arguments.contains("-pass-auth-logs")
    private static let OPEN_INSPECTOR: Bool = CommandLine.arguments.contains("-open-cwa-inspector")
    
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
                parent.logger.error("Error occurred when authenticating AM User: \(json["message"].stringValue)")
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
        self.wkWebView = WKWebView(frame: .zero).then {
#if DEBUG
            $0.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
#endif
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
                
                if let lastAmUserToken = try? self.cacheModel.storage?.object(forKey: "last_am_usertoken") {
                    self.logger.success("Logged in with previously cached user token", displayTick: true)
                    DispatchQueue.main.async {
                        continuation.resume(returning: lastAmUserToken)
                    }
                    return
                }
                
                let ua = await Networking.findLatestWebViewUA()
                DispatchQueue.main.async {
                    let userScript = WKUserScript(source: """
                                                  const initialURL = \"\(AuthModal.INITIAL_URL)\";
                                                  const amToken = \"\(developerToken)\";
                                                  \(precompileIncludeStr("@/CiderWebModules/dist/am-auth.js"))
                                                  """, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
                    self.wkWebView?.customUserAgent = ua
                    self.wkWebView?.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
                    self.wkWebView?.configuration.userContentController.addUserScript(userScript)
                    
                    if AuthModal.OPEN_INSPECTOR {
                        #if DEBUG
                        if let inspector = self.wkWebView?.value(forKey: "_inspector") as? AnyObject {
                            _ = inspector.perform(Selector(("showConsole")))
                        }
                        #endif
                    }
                    
                    if self.mkModal.isAuthorised, let userToken = self.mkModal.AM_API.AM_USER_TOKEN {
                        self.logger.success("Logged in with previously fetched user token", displayTick: true)
                        continuation.resume(returning: userToken)
                    }
                    
                    self.authenticatingCallback = { userToken in
                        do {
                            try self.cacheModel.storage?.setObject(userToken, forKey: "last_am_usertoken", expiry: .date(Date().addingTimeInterval(7 * 60 * 60)))
                        } catch {
                            self.logger.error("Failed to cache Apple Music user token: \(error)")
                        }
                        DispatchQueue.main.async {
                            continuation.resume(returning: userToken)
                        }
                        self.wkWebView?.load(URLRequest(url: URL(string: "about:blank")!))
                        
                        // hack to dispose wkwebview manually
                        //            let disposeSel: Selector = NSSelectorFromString("_killWebContentProcess")
                        //            self.wkWebView?.perform(disposeSel)
                        
                        self.wkWebView?.removeFromSuperview()
                        self.authWindow.close()
                        
                        self.wkWebView = nil
                    }
                    
                    // loadSimulatedRequest for some reason doesn't not work in sandbox mode
#if !os(macOS)
                    // go to /stub so it doesn't load all the images in Apple Music Web's homepage
                    self.wkWebView?.load(URLRequest(url: URL(string: "https://music.apple.com/stub")!))
#else
                    self.wkWebView?.loadSimulatedRequest(AuthModal.INITIAL_URL, responseHTML: precompileIncludeStr("@/CiderWebModules/dist/am-auth.html"))
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
    
    func clearAuthCache() async {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                URLCache.shared.removeAllCachedResponses()
                HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
                WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) {
                    // TODO: better way to handle signout
                    Logger.shared.info("Successfully cleared auth cache")
                    continuation.resume()
                }
            }
        }
    }
    
}
#endif
