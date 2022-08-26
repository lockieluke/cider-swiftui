//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import AppKit
import SwiftUI

class AppWindow {
    
    private let mainWindow: NSWindow
    
    init() {
        let activeScreen = NSScreen.activeScreen
        let window = NSWindow(contentViewController: NSHostingController(rootView: ContentView()))
        
        window.setContentSize(NSSize(width: 1280, height: 720))
        window.styleMask = [.miniaturizable, .closable, .resizable, .titled]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.title = "Cider"
        
        let toolbar = NSToolbar()
        window.toolbar = toolbar
        window.toolbarStyle = .unified
        
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
