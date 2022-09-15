//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import WebKit
import SwiftUI
import SwiftyJSON

final class AuthWorkerView : NSViewRepresentable {
    
    private let wkWebView: WKWebView
    private var wkUIDelegate: AuthWorkerUIDelegate?
    
    static var shared: AuthWorkerView! = nil
    private static let INITIAL_URL = URLRequest(url: URL(string: "https://www.apple.com/legal/privacy/en-ww/cookies/")!)
    private static let USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_5_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.6 Safari/605.1.15"
    private static let IS_FORGETTING_AUTH: Bool = CommandLine.arguments.contains("-clear-auth")
    
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
            
            if let action = json["action"].string {
                switch action {
                    
                case "authenticated":
                    let token = json["token"].stringValue
                    parent.authenticatingCallback?(token)
                    break
                    
                default:
                    break
                    
                }
            }
            
            if json["error"].exists() {
                fatalError("Error occurred when authenticating AM User: \(json["error"].error?.localizedDescription ?? "No error description")")
            }
            
            completionHandler()
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            let request = navigationAction.request
            if let url = navigationAction.request.url {
                if url.absoluteString.contains("https://authorize.music.apple.com") {
                    webView.load(request)
                }
            }
            return nil
        }
        
    }
    
    init(authenticatingCallback: ((_ userToken: String) -> Void)? = nil) {
        if AuthWorkerView.IS_FORGETTING_AUTH {
            AuthWorkerView.clearAuthCache()
        }
        
        self.authenticatingCallback = authenticatingCallback
        
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
        
        AuthWorkerView.shared = self
    }
    
    func makeNSView(context: Context) -> WKWebView {
        self.wkUIDelegate = AuthWorkerUIDelegate(parent: self)
        
        wkWebView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        wkWebView.customUserAgent = AuthWorkerView.USER_AGENT
        
        wkWebView.uiDelegate = wkUIDelegate
        
        wkWebView.load(AuthWorkerView.INITIAL_URL)
        return wkWebView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        
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
