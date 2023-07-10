//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

#if canImport(AppKit)
import Foundation
import AppKit
import SwiftUI
import SnapKit

class AppWindow: NSObject, NSWindowDelegate {
    
    private let mainWindow: NSWindow
    private let appWindowModal = AppWindowModal()
    private let mkModal: MKModal
    private let discordRPCModal: DiscordRPCModal
    private let nativeUtilsWrapper: NativeUtilsWrapper
    private let wsModal = WSModal.shared
    private let authWorker: AuthWorker
    private let appMenu: AppMenu
    
    let ciderPlayback: CiderPlayback
    
    init(discordRPCModal: DiscordRPCModal, nativeUtilsWrapper: NativeUtilsWrapper) {
        let activeScreen = NSScreen.activeScreen
        
        let discordRPCModal = DiscordRPCModal()
        let ciderPlayback = CiderPlayback(appWindowModal: self.appWindowModal, discordRPCModal: discordRPCModal)
        let mkModal = MKModal(ciderPlayback: ciderPlayback)
        let authWorker = AuthWorker(mkModal: mkModal, appWindowModal: self.appWindowModal)
        
        let contentView = ContentView(authWorker: authWorker)
            .environmentObject(self.appWindowModal)
            .environmentObject(mkModal)
            .environmentObject(ciderPlayback)
            .environmentObject(discordRPCModal)
            .environmentObject(nativeUtilsWrapper)
            .frame(minWidth: 900, maxWidth: .infinity, minHeight: 390, maxHeight: .infinity)
        
        let window = NSWindow(contentRect: .zero, styleMask: [.miniaturizable, .closable, .resizable, .titled, .fullSizeContentView], backing: .buffered, defer: false).then {
            $0.contentViewController = NSHostingController(rootView: contentView)
            $0.setFrame(NSRect(x: .zero, y: .zero, width: 1024, height: 600), display: true)
            $0.isOpaque = true
            $0.backgroundColor = .clear
            $0.titlebarAppearsTransparent = true
            $0.titleVisibility = .hidden
            $0.title = Bundle.main.displayName
            
//            let toolbar = NSToolbar()
//            $0.showsToolbarButton = false
//            $0.toolbar = toolbar
            
            var pos = NSPoint()
            pos.x = activeScreen.visibleFrame.midX
            pos.y = activeScreen.visibleFrame.midY
            $0.setFrameOrigin(pos)
            $0.isReleasedWhenClosed = false
            $0.center()
        }
        
        defer {
            window.delegate = self
            
            self.updateWindowButtons()
        }
        
        let appMenu = AppMenu(window,
                              mkModal: mkModal,
                              authWorker: authWorker,
                              wsModal: self.wsModal,
                              ciderPlayback: ciderPlayback,
                              appWindowModal: self.appWindowModal,
                              nativeUtilsWrapper: nativeUtilsWrapper
        )
        appMenu.loadMenus()

        self.mainWindow = window
        self.appWindowModal.nsWindow = window
        self.authWorker = authWorker
        self.discordRPCModal = discordRPCModal
        self.nativeUtilsWrapper = nativeUtilsWrapper
        self.appMenu = appMenu
        self.mkModal = mkModal
        self.ciderPlayback = ciderPlayback
        
        super.init()
    }
    
    func updateWindowButtons() {
        if let closeButton = self.mainWindow.standardWindowButton(.closeButton), let minimiseButton = self.mainWindow.standardWindowButton(.miniaturizeButton), let zoomButton = self.mainWindow.standardWindowButton(.zoomButton) {
            
            func updateWindowButton(_ button: NSButton) {
                button.snp.makeConstraints { make in
                    make.top.equalTo(17)
                    
                    let currentX = button.frame.origin.x
                    make.left.left.equalTo(currentX + 10.0)
                }
            }
            
            updateWindowButton(closeButton)
            updateWindowButton(minimiseButton)
            updateWindowButton(zoomButton)
        }
    }
    
    func show() {
        self.mainWindow.makeKeyAndOrderFront(nil)
        if !self.mainWindow.isMainWindow {
            self.mainWindow.makeMain()
        }
        NSApp.mainMenu = self.appMenu.getMenu()
        
        self.appWindowModal.isFocused = true
        self.appWindowModal.isVisibleInViewport = true
    }
    
    func getWindow() -> NSWindow {
        return self.mainWindow
    }
    
    func window(_ window: NSWindow, willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions = []) -> NSApplication.PresentationOptions {
        return [.fullScreen, .autoHideDock, .autoHideToolbar, .autoHideMenuBar]
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        self.appWindowModal.isFocused = true
    }
    
    func windowDidResignKey(_ notification: Notification) {
        self.appWindowModal.isFocused = false
    }
    
    func windowDidExpose(_ notification: Notification) {
        self.appWindowModal.isVisibleInViewport = true
    }
    
    func windowDidChangeOcclusionState(_ notification: Notification) {
        self.appWindowModal.isVisibleInViewport = self.mainWindow.isVisible && self.mainWindow.occlusionState.contains(.visible) && self.mainWindow.isOnActiveSpace
    }
    
    func windowDidEnterFullScreen(_ notification: Notification) {
        self.appWindowModal.isFullscreen = true
    }
    
    func windowDidExitFullScreen(_ notification: Notification) {
        self.appWindowModal.isFullscreen = false
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }
    
}

#endif
