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
        
    }
    
    init() {
        let activeScreen = NSScreen.activeScreen
        let window = NSWindow(contentViewController: NSHostingController(rootView: ContentView()))
        
        window.setContentSize(NSSize(width: 1024, height: 600))
        window.styleMask = [.miniaturizable, .closable, .resizable, .titled, .fullSizeContentView]
        window.isOpaque = true
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.title = "Cider"
        
        self.windowDelegate = AppWindowDelegate()
        window.delegate = windowDelegate
        
        let toolbar = NSToolbar()
        window.showsToolbarButton = false
        window.toolbar = toolbar
        
        var pos = NSPoint()
        pos.x = activeScreen.visibleFrame.midX
        pos.y = activeScreen.visibleFrame.midY
        window.setFrameOrigin(pos)
        window.center()

        self.mainWindow = window
    }
    
    func show() {
        self.mainWindow.makeKeyAndOrderFront(nil)
        self.mainWindow.makeMain()
    }
    
}
