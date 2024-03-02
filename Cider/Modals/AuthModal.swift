//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import Foundation
import WebKit
import SwiftUI
import KeychainAccess

#if canImport(AppKit)
import AppKit
class AuthModal: ObservableObject {
    
    private let logger = Logger(label: "AuthModal")
    private let keychain = Keychain()
    private let mkModal: MKModal
    private lazy var scriptHandler = AuthScriptHandler(parent: self)
    private lazy var webUIDelegate = AuthUIDelegate(parent: self)
    private lazy var navigationDelegate = AuthNavigationDelegate(parent: self)
    private var amDeveloperToken: String?
    private var signoutCallback: (() -> Void)?
    let webview: WKWebView
    
    private static let INITIAL_URL = URLRequest(url: URL(string: "https://www.apple.com/legal/privacy/en-ww/cookies/")!)
    private static let IS_PASSING_LOGS: Bool = CommandLine.arguments.contains("-pass-auth-logs")
    private static let OPEN_INSPECTOR: Bool = CommandLine.arguments.contains("-open-cwa-inspector")
    
    class AuthScriptHandler: NSObject, WKScriptMessageHandler {
        
        private weak var parent: AuthModal! = nil
        
        init(parent: AuthModal) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "ciderkit" {
                guard let dict = message.body as? [String: AnyObject] else { return }
                guard let eventName = dict["event"] as? String else { return }
                
                if eventName == "error", let message = dict["message"] {
                    self.parent.logger.error("\(String(describing: message))")
                } else if eventName == "authenticated", let token = dict["token"] as? String {
                    self.parent.keychain["mk-token"] = token
                    Task {
                        await self.parent.mkModal.authenticateWithToken(userToken: token)
                        await self.parent.mkModal.initStorefront()
                        DispatchQueue.main.async {
                            self.parent.mkModal.isAuthorised = true
                        }
                    }
                } else if eventName == "signout-complete" {
                    self.parent.keychain["mk-token"] = nil
                    self.parent.signoutCallback?()
                    do {
                        self.parent.signoutCallback = nil
                        self.parent.loadPage(params: [
                            URLQueryItem(name: "manual-signin", value: nil)
                        ])
                    }
                } else {
                    print(eventName, dict)
                }
            }
        }
    }
    
    class AuthNavigationDelegate: NSObject, WKNavigationDelegate {
        
        private weak var parent: AuthModal! = nil
        
        init(parent: AuthModal) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            let exceptedHosts = [
                "support.apple.com"
            ]
            
            if let host = navigationAction.request.url?.host {
                if exceptedHosts.contains(host) {
                    return .cancel
                }
            }
            
            return .allow
        }
        
    }
    
    class AuthUIDelegate: NSObject, WKUIDelegate {
        
        private weak var parent: AuthModal! = nil
        
        init(parent: AuthModal) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo) async {
            if let mainWindow = await NSApp.mainWindow {
                await Alert.showModal(on: mainWindow, message: message)
            }
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            let request = navigationAction.request
            if let url = navigationAction.request.url {
                if url.absoluteString.contains("apple.com") {
                    self.parent.webview.load(request)
                }
            }
            return nil
        }
        
    }
    
    init(mkModal: MKModal, ciderPlayback: CiderPlayback) {
        self.webview = WKWebView(frame: .zero).then {
            $0.setValue(false, forKey: "drawsBackground")
#if DEBUG
            $0.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
            $0.load(URLRequest(url: URL(string: "http://localhost:5173/am-auth")!))
#else
            // MusicKit JS refueses to give us the token unless we have a properly formed URL with port and path
            $0.loadSimulatedRequest(URLRequest(url: URL(string: "https://localhost:5173/am-auth")!), responseHTML: precompileIncludeStr("@/CiderWebModules/dist/am-auth.html"))
#endif
            
            if AuthModal.OPEN_INSPECTOR {
#if DEBUG
                if let inspector = $0.value(forKey: "_inspector") as? AnyObject {
                    _ = inspector.perform(Selector(("showConsole")))
                }
#endif
            }
        }
        self.mkModal = mkModal
        defer {
            self.webview.uiDelegate = self.webUIDelegate
            self.webview.navigationDelegate = self.navigationDelegate
            self.webview.configuration.userContentController.add(self.scriptHandler, name: "ciderkit")
            Task {
                if let developerToken = try? await mkModal.fetchDeveloperToken() {
                    await ciderPlayback.setDeveloperToken(developerToken: developerToken)
                    DispatchQueue.main.async {
                        self.amDeveloperToken = developerToken
                        self.webview.configuration.userContentController.addUserScript(WKUserScript(source: "window.AM_TOKEN=\"\(developerToken)\";\(precompileIncludeStr("@/CiderWebModules/dist/am-auth.js"))", injectionTime: .atDocumentStart, forMainFrameOnly: true))
                    }
                }
            }
        }
    }
    
    private func loadPage(params: [URLQueryItem] = []) {
        let params = params.map { "\($0.name)\($0.value.isNil ? "" : "=\($0.value!)")" }.joined(separator: "&")
#if DEBUG
        webview.load(URLRequest(url: URL(string: "http://localhost:5173/am-auth?\(params)")!))
#else
        webview.loadSimulatedRequest(URLRequest(url: URL(string: "https://localhost:5173/am-auth?\(params)")!), responseHTML: precompileIncludeStr("@/CiderWebModules/dist/am-auth.html"))
#endif
    }
    
    func dispose() {
        let disposeSel: Selector = NSSelectorFromString("_killWebContentProcess")
        self.webview.perform(disposeSel)
    }
    
    func unauthorise() async {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.keychain["mk-token"] = nil
                self.loadPage(params: [
                    URLQueryItem(name: "signout", value: "true")
                ])
                self.signoutCallback = {
                    continuation.resume()
                }
            }
        }
    }
    
    
}
#endif
