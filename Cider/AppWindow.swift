//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import AppKit
import SwiftUI

class AppWindow: NSObject, NSWindowDelegate {
    
    private let mainWindow: NSWindow
    private let appWindowModal = AppWindowModal()
    private let mkModal: MKModal
    private let discordRPCModal: DiscordRPCModal
    private let wsModal = WSModal.shared
    private let authWorker: AuthWorker
    private let appMenu: AppMenu
    
    let ciderPlayback: CiderPlayback
    
    init(discordRPCModal: DiscordRPCModal) {
        let activeScreen = NSScreen.activeScreen
        let window = NSWindow(contentRect: .zero, styleMask: [.miniaturizable, .closable, .resizable, .titled, .fullSizeContentView], backing: .buffered, defer: false)
        
        let discordRPCModal = DiscordRPCModal()
        let ciderPlayback = CiderPlayback(appWindowModal: self.appWindowModal, discordRPCModal: discordRPCModal)
        let mkModal = MKModal(ciderPlayback: ciderPlayback)
        let authWorker = AuthWorker(mkModal: mkModal, appWindowModal: self.appWindowModal)
        
        let contentView = ContentView(authWorker: authWorker)
            .environmentObject(self.appWindowModal)
            .environmentObject(mkModal)
            .environmentObject(ciderPlayback)
            .environmentObject(discordRPCModal)
            .frame(minWidth: 900, maxWidth: .infinity, minHeight: 390, maxHeight: .infinity)
        window.contentViewController = NSHostingController(rootView: contentView)
        window.setFrame(NSRect(x: .zero, y: .zero, width: 1024, height: 600), display: true)
        window.isOpaque = true
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.title = Bundle.main.displayName
        
        defer {
            window.delegate = self
        }
        
        let toolbar = NSToolbar()
        window.showsToolbarButton = false
        window.toolbar = toolbar
        
        var pos = NSPoint()
        pos.x = activeScreen.visibleFrame.midX
        pos.y = activeScreen.visibleFrame.midY
        window.setFrameOrigin(pos)
        window.isReleasedWhenClosed = false
        window.center()
        
        let appMenu = AppMenu(window,
                              mkModal: mkModal,
                              authWorker: authWorker,
                              wsModal: self.wsModal,
                              ciderPlayback: ciderPlayback,
                              appWindowModal: self.appWindowModal
        )
        appMenu.loadMenus()

        self.mainWindow = window
        self.appWindowModal.nsWindow = window
        self.authWorker = authWorker
        self.discordRPCModal = discordRPCModal
        self.appMenu = appMenu
        self.mkModal = mkModal
        self.ciderPlayback = ciderPlayback
        
        super.init()
    }
    
    func show() {
        mainWindow.makeKeyAndOrderFront(nil)
        if !mainWindow.isMainWindow {
            mainWindow.makeMain()
        }
        NSApp.mainMenu = appMenu.getMenu()
        
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
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }
    
}
