//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import AppKit
import SwiftUI

class WSDebugger {
    
    private let window: NSWindow
    
    init(wsModal: WSModal, ciderPlayback: CiderPlayback, appWindowModal: AppWindowModal) {
        let window = NSWindow(contentRect: NSRect(x: .zero, y: .zero, width: 480, height: 360), styleMask: [.closable, .miniaturizable, .resizable, .titled, .unifiedTitleAndToolbar], backing: .buffered, defer: false)
        window.title = "WebSockets Debugger - \(Bundle.main.displayName)"
        window.isReleasedWhenClosed = false
        
        let vc = WSDebuggerView()
            .environmentObject(wsModal)
            .environmentObject(ciderPlayback)
            .environmentObject(appWindowModal)
            .frame(minWidth: 480, maxWidth: .infinity, minHeight: 360, maxHeight: .infinity)
        window.contentViewController = NSHostingController(rootView: vc)
        
        self.window = window
    }
    
    func open() {
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
    
}

