//
//  WebUIIsland.swift
//  Cider
//
//  Created by Sherlock LUK on 29/02/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject
import WebKit

struct WebUIIsland: View {
    
    @ObservedObject private var iO = Inject.observer
    
    private let logger: Logger
    private let name: String
    private let staticHtml: String
    private let webview: WKWebView
    private let onMessage: ((String, [String: AnyObject], WKWebView) -> Void)?
    private lazy var wkUIDelegate = WebUIIslandUIDelegate(parent: self)
    private lazy var wkMessageHandler = WebUIIslandMessageHandler(parent: self)
    
    class WebUIIslandUIDelegate: NSObject, WKUIDelegate {
        private let parent: WebUIIsland!
        
        init(parent: WebUIIsland) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo) async {
            if let mainWindow = await NSApp.keyWindow {
                await Alert.showModal(on: mainWindow, message: message)
            }
        }
    }
    
    class WebUIIslandMessageHandler: NSObject, WKScriptMessageHandler {
        private let parent: WebUIIsland!
        
        init(parent: WebUIIsland) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "ciderkit" {
                guard let dict = message.body as? [String: AnyObject], let eventName = dict["event"] as? String else { return }

                self.parent.onMessage?(eventName, dict, self.parent.webview)
            }
        }
    }
    
    private func loadPage() {
        #if DEBUG
        // has to be http to support hot reload
        self.webview.load(URLRequest(url: URL(string: "http://localhost:5173/\(self.name)")!))
        #else
        self.webview.loadHTMLString(self.staticHtml, baseURL: URL(string: "https://localhost:5173")!)
        #endif
    }
    
    private func dispose() {
        let disposeSel: Selector = NSSelectorFromString("_killWebContentProcess")
        self.webview.perform(disposeSel)
    }
    
    init(name: String, staticHtml: String, _ onMessage: ((String, [String: AnyObject], WKWebView) -> Void)? = nil) {
        self.logger = Logger(label: "Web UI Island - \(name)")
        self.name = name
        self.staticHtml = staticHtml
        self.onMessage = onMessage
        self.webview = WKWebView().then {
            $0.setValue(false, forKey: "drawsBackground")
            #if DEBUG
            $0.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
            #endif
        }
        defer {
            self.webview.uiDelegate = self.wkUIDelegate
            self.webview.configuration.userContentController.add(self.wkMessageHandler, name: "ciderkit")
        }
    }
    
    var body: some View {
        NativeComponent(self.webview)
            .if(Diagnostic.isDebug) { view in
                view
                    .overlay {
                        Button {
                            self.logger.info("Reloading")
                            self.webview.evaluateJavaScript("location.reload()")
                        } label: {
                            Text("Reload")
                        }
                        .isHidden(true, remove: false)
                        .keyboardShortcut("r", modifiers: [.command])
                    }
            }
            .onAppear {
                self.loadPage()
            }
            .onDisappear {
                self.dispose()
            }
            .enableInjection()
    }
}

#Preview {
    WebUIIsland(name: "am-auth", staticHtml: precompileIncludeStr("@/CiderWebModules/dist/am-auth.html"))
}
