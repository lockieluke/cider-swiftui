//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import AppKit
import SwiftUI

class AppWindow {
    
    private let mainWindow: NSWindow
    private let windowDelegate: AppWindowDelegate
    
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
        let window = NSWindow(contentRect: NSRect(x: .zero, y: .zero, width: 1024, height: 600), styleMask: [.miniaturizable, .closable, .resizable, .titled, .fullSizeContentView], backing: .buffered, defer: false)
        
        let contentView = ContentView()
            .frame(minWidth: 820, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
        window.contentViewController = NSHostingController(rootView: contentView)
        window.setContentSize(NSSize(width: 1024, height: 600))
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

        self.mainWindow = window
        AppWindowModal.shared.nsWindow = window
    }
    
    func show() {
        mainWindow.makeKeyAndOrderFront(nil)
        if !mainWindow.isMainWindow {
            mainWindow.makeMain()
        }
    }
    
    func getWindow() -> NSWindow {
        return self.mainWindow
    }
    
}
