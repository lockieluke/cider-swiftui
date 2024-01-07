//
//  ConnectModal.swift
//  Cider
//
//  Created by Sherlock LUK on 18/08/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import Defaults
import FirebaseAuth
import GoogleSignIn
import SwiftyJSON
import Swifter
import WebKit
import SwiftUI

enum SignInMethod: String, Defaults.Serializable {
    case apple = "/apple-auth"
    case google = "/google-auth"
    case azure = "/azure-auth"
    
    var humanReadableName: String {
        switch self {
        case .apple:
            return "Apple"
            
        case .google:
            return "Google"
            
        case .azure:
            return "Azure"
        }
    }
}

class ConnectModal: ObservableObject {
    
    @Published var isSignedIn: Bool = false
    @Published var user: User?
    @Published var currentSignInMethod: SignInMethod?
    
    let view: NSView
    private let wkWebView: WKWebView
    private let server: HttpServer
    private let logger = Logger(label: "CiderConnectAuth")
    
    private var authHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    private var connectWebViewUIDelegate: ConnectWebViewUIDelegate?
    private var authenticatingCallback: (() -> Void)?
    private var userAgent: String?
    
    class ConnectWebViewUIDelegate: NSObject, WKUIDelegate {
        
        weak var parent: ConnectModal! = nil
        
        init(parent: ConnectModal) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            guard let messageData = message.data(using: .utf8) else {
                completionHandler()
                return
            }
            guard let json = try? JSON(data: messageData) else {
                completionHandler()
                return
            }
            
            if let action = json["action"].string {
                switch action {
                    
                case "error":
                    self.parent.logger.error("\(json["message"].stringValue)")
                    break
                    
                case "auth-success":
                    if let signInMethod = SignInMethod(rawValue: json["signInMethod"].stringValue) {
                        self.parent.authenticateUser(idToken: json["idToken"].stringValue, accessToken: json["accessToken"].stringValue, signInMethod: signInMethod)
                    }
                    break
                    
                case "sign-out-success":
                    do {
                        try Auth.auth().signOut()
                        self.parent.isSignedIn = false
                        self.parent.user = nil
                        self.parent.currentSignInMethod = nil
                        Defaults[.signInMethod] = .none
                    } catch {
                        print(error.localizedDescription)
                    }
                    self.parent.logger.info("Successfully signed out of Cider Connect")
                    self.parent.server.stop()
                    break
                    
                default:
                    break
                    
                }
            }
            
            completionHandler()
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            let request = navigationAction.request
            if let url = request.url {
                let whitelist = [
                    "apple.com",
                    "cider-collective.firebaseapp.com"
                ]
                
                var host: String?
                if #available(macOS 13.0, *) {
                    host = url.host(percentEncoded: true)
                } else {
                    host = url.host
                }
                
                if host.isNotNilNotEmpty, whitelist.contains(host!) {
                    guard let userJsPath = Bundle.main.sharedSupportURL?.appendingPathComponent("handle-googleauth-unsafe-dialog.js"),
                          let userJsScript = try? String(contentsOfFile: userJsPath.path, encoding: .utf8) else {
                        fatalError("Unable to load CiderConnectAuth user script")
                    }
                    
                    let newWebView = WKWebView(frame: webView.frame, configuration: configuration).then {
                        $0.customUserAgent = self.parent.userAgent
                        $0.configuration.userContentController.addUserScript(WKUserScript(source: userJsScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
                    }
                    self.parent.view.addSubview(newWebView)
                    return newWebView
                }
            }
            return nil
        }
        
    }
    
    init() {
        guard let jsPath = Bundle.main.sharedSupportURL?.appendingPathComponent("cider-connect.js"),
              let jsScript = try? String(contentsOfFile: jsPath.path, encoding: .utf8) else {
            fatalError("Unable to load CiderConnectAuth Scripts")
        }
        
        let server = HttpServer()
        let serve = scopes {
            html {
                body {
                    script {
                        inner = jsScript
                    }
                }
            }
        }
        
        server["/apple-auth"] = serve
        server["/google-auth"] = serve
        server["/azure-auth"] = serve
        server["/sign-out"] = serve
        
        self.wkWebView = WKWebView().then {
#if DEBUG
            $0.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
#endif
            $0.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
            $0.autoresizingMask = [.width, .height]
        }
        self.view = NSView().then {
            $0.autoresizesSubviews = true
        }
        self.server = server
        
        let currentUser = Auth.auth().currentUser
        self.user = currentUser
        self.isSignedIn = !currentUser.isNil
        if currentUser.isNil {
            Defaults[.signInMethod] = .none
        }
        self.currentSignInMethod = Defaults[.signInMethod]
        
        defer {
            self.authHandle = Auth.auth().addStateDidChangeListener { auth, user in
                self.isSignedIn = !auth.currentUser.isNil
                self.currentSignInMethod = Defaults[.signInMethod]
            }
            
            self.connectWebViewUIDelegate = ConnectWebViewUIDelegate(parent: self)
            self.wkWebView.uiDelegate = self.connectWebViewUIDelegate
        }
    }
    
    private func startServer() -> UInt16 {
        let port = Networking.findFreeLocalPort()
        
        do {
            try self.server.start(port)
        } catch {
            self.logger.error("Failed to start CiderConnectAuth server: \(error)")
        }
        
        return port
    }
    
    func restoreUser() {
        
    }

    func signIn(signInMethod: SignInMethod, _ authenticatingCallback: (() -> Void)? = nil) async {
        self.authenticatingCallback = authenticatingCallback
        
        let port = self.startServer()
        let ua = await Networking.findLatestWebViewUA()
        DispatchQueue.main.async {
            self.wkWebView.customUserAgent = ua
            self.view.addSubview(self.wkWebView)
            
            self.wkWebView.load(URLRequest(url: URL(string: "http://localhost:\(port)\(signInMethod.rawValue)")!))
            self.userAgent = ua
        }
    }
    
    func authenticateUser(idToken: String, accessToken: String, signInMethod: SignInMethod) {
        var credential: AuthCredential? = nil
        if signInMethod == .apple {
            credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idToken, accessToken: accessToken)
        } else if signInMethod == .google {
            credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        } else if signInMethod == .azure {
            credential = OAuthProvider.credential(withProviderID: "microsoft.com", idToken: idToken, accessToken: accessToken)
        }
        
        if (credential.isNil) {
            return
        }
        Auth.auth().signIn(with: credential!) { (authResult, error) in
            if let error = error {
                if let provider = credential?.provider {
                    self.logger.error("Unable to sign in with \(provider): \(error.localizedDescription)")
                }
                return
            }
            
            if let user = authResult?.user, let email = user.email {
                self.logger.success("Successfully signed into Cider Connect: \(email)")
                self.authenticatingCallback?()
                self.user = user
                self.isSignedIn = true
                self.currentSignInMethod = signInMethod
                Defaults[.signInMethod] = signInMethod
            }
        }
    }
    
    func cleanupWebView() {
        self.server.stop()
        self.wkWebView.load(URLRequest(url: URL(string: "about:blank")!))
        self.wkWebView.removeFromSuperview()
    }
    
    deinit {
        Auth.auth().removeStateDidChangeListener(self.authHandle!)
    }
    
    func signOut() {
        if self.user.isNil || self.currentSignInMethod.isNil {
            return
        }
        
        let port = self.startServer()
        self.wkWebView.load(URLRequest(url: URL(string: "http://localhost:\(port)/sign-out")!))
        
        if self.currentSignInMethod == .google {
            GIDSignIn.sharedInstance.signOut()
        }
    }
    
}
