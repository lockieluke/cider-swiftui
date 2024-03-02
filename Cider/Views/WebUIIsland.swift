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
    
    private func loadPage() {
        #if DEBUG
        // has to be http to support hot reload
        self.webview.load(URLRequest(url: URL(string: "http://localhost:5173/\(self.name)")!))
        #else
        self.webview.loadHTMLString(self.staticHtml, baseURL: URL(string: "https://localhost:5173")!)
        #endif
    }
    
    init(name: String, staticHtml: String) {
        self.logger = Logger(label: "Web UI Island - \(name)")
        self.name = name
        self.staticHtml = staticHtml
        self.webview = WKWebView().then {
            $0.setValue(false, forKey: "drawsBackground")
            #if DEBUG
            $0.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
            #endif
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
            .enableInjection()
    }
}

#Preview {
    WebUIIsland(name: "am-auth", staticHtml: precompileIncludeStr("@/CiderWebModules/dist/am-auth.html"))
}
