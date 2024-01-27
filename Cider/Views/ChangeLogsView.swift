//
//  ChangeLogsView.swift
//  Cider
//
//  Created by Sherlock LUK on 06/01/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject
import WebKit
import Defaults

struct ChangeLogsView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var appWindowModal: AppWindowModal
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var sheetHeight: CGFloat = .zero
    
    private let wkWebView: WKWebView
    
    private class ChangelogsViewWKNavigationDelegate: NSObject, WKNavigationDelegate {
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task {
                if let changelogs = await UpdateHelper.shared.fetchCurrentChangelogs() {
                    do {
                        _ = try await webView.callAsyncJavaScript("return window.setMarkdown(markdown)", arguments: ["markdown": changelogs], contentWorld: .page)
                    } catch {
                        print("Failed to render markdown: \(error.localizedDescription)")
                    }
                }
            }
        }
        
    }
    private let wkNavigationDelegate: ChangelogsViewWKNavigationDelegate
    
    init() {
        let wkNavigationDelegate = ChangelogsViewWKNavigationDelegate()
        self.wkWebView = WKWebView(frame: .zero).then {
            $0.navigationDelegate = wkNavigationDelegate
            $0.setValue(false, forKey: "drawsBackground")
            $0.configuration.userContentController.addUserScript(WKUserScript(source: "window.BUILD_INFO = { version: \"\(Bundle.main.appVersion)\", build: \(Bundle.main.appBuild) };", injectionTime: .atDocumentStart, forMainFrameOnly: true, in: .page))
            #if DEBUG
            $0.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
            $0.load(URLRequest(url: URL(string: "http://localhost:5173/changelogs")!))
            #else
            $0.loadHTMLString(precompileIncludeStr("@/CiderWebModules/dist/changelogs.html"), baseURL: URL(string: "http://localhost")!)
            #endif
        }
        self.wkNavigationDelegate = wkNavigationDelegate
    }
    
    var body: some View {
        let size = appWindowModal.nsWindow?.frame
        ZStack {
            HStack {
                #if DEBUG
                Button {
                    self.wkWebView.loadHTMLString(precompileIncludeStr("@/CiderWebModules/dist/changelogs.html"), baseURL: URL(string: "http://localhost")!)
                } label: {
                    Text("Load static build")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding()
                #endif
                Spacer()
                Button() {
                    self.dismiss()
                } label: {
                    Image(systemSymbol: .xmarkCircleFill)
                        .font(.title2)
                }
                .buttonStyle(.borderless)
                .padding()
            }
            .frame(maxHeight: .infinity, alignment: .topTrailing)
            
            NativeComponent(self.wkWebView)
                .transparentScrollbars()
                .clipShape(Rectangle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .padding(.top, 30)
        }
        .frame(width: (size?.width ?? .zero) * 0.85, height: (size?.height ?? .zero) * 0.85)
        .onAppear {
            Defaults[.lastShownChangelogs] = "\(Bundle.main.appVersion)-\(Bundle.main.appBuild)"
        }
        .enableInjection()
    }
}

#Preview {
    ChangeLogsView()
}
