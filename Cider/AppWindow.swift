//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import AppKit
import SwiftUI

class AppWindow {
    
    private let mainWindow: NSWindow
    private let windowDelegate: AppWindowDelegate
    private let appWindowModal = AppWindowModal()
    private let mkModal: MKModal
    private let prefModal = PrefModal()
    private let authWorker: AuthWorker
    private let appMenu: AppMenu
    
    let ciderPlayback: CiderPlayback
    
    class AppWindowDelegate : NSObject, NSWindowDelegate {
        
        func window(_ window: NSWindow, willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions = []) -> NSApplication.PresentationOptions {
            return [.fullScreen, .autoHideDock, .autoHideToolbar, .autoHideMenuBar]
        }
        
        func windowShouldClose(_ sender: NSWindow) -> Bool {
            return true
        }
        
    }
    
    init() {
        let activeScreen = NSScreen.activeScreen
        let window = NSWindow(contentRect: .zero, styleMask: [.miniaturizable, .closable, .resizable, .titled, .fullSizeContentView], backing: .buffered, defer: false)
        
        let ciderPlayback = CiderPlayback(prefModal: self.prefModal)
        let mkModal = MKModal(ciderPlayback: ciderPlayback)
        let authWorker = AuthWorker(mkModal: mkModal, appWindowModal: self.appWindowModal)
        
        let contentView = ContentView(authWorker: authWorker)
            .environmentObject(self.appWindowModal)
            .environmentObject(mkModal)
            .environmentObject(ciderPlayback)
            .environmentObject(self.prefModal)
            .frame(minWidth: 900, maxWidth: .infinity, minHeight: 390, maxHeight: .infinity)
        window.contentViewController = NSHostingController(rootView: contentView)
        window.setFrame(NSRect(x: .zero, y: .zero, width: 1024, height: 600), display: true)
        window.isOpaque = true
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        if let displayName = Bundle.main.displayName {
            window.title = displayName
        }
        
        self.windowDelegate = AppWindowDelegate()
        window.delegate = windowDelegate
        
        let toolbar = NSToolbar()
        window.showsToolbarButton = false
        window.toolbar = toolbar
        
        var pos = NSPoint()
        pos.x = activeScreen.visibleFrame.midX
        pos.y = activeScreen.visibleFrame.midY
        window.setFrameOrigin(pos)
        window.isReleasedWhenClosed = false
        window.center()
        
        let appMenu = AppMenu(window, mkModal: mkModal, authWorker: authWorker, prefModal: prefModal)
        appMenu.loadMenus()

        self.mainWindow = window
        self.appWindowModal.nsWindow = window
        self.authWorker = authWorker
        self.appMenu = appMenu
        self.mkModal = mkModal
        self.ciderPlayback = ciderPlayback
    }
    
    func show() {
        mainWindow.makeKeyAndOrderFront(nil)
        if !mainWindow.isMainWindow {
            mainWindow.makeMain()
        }
        NSApp.mainMenu = appMenu.getMenu()
    }
    
    func getWindow() -> NSWindow {
        return self.mainWindow
    }
    
}
