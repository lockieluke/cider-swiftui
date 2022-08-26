//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import AppKit

class AppMenu : NSMenu {
    
    private lazy var applicationName = ProcessInfo.processInfo.processName
    
    override init(title: String) {
        super.init(title: title)
        
        let menuItemOne = NSMenuItem()
        menuItemOne.submenu = NSMenu(title: "menuItemOne")
        menuItemOne.submenu?.items = [NSMenuItem(title: "Quit \(applicationName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")]
        items = [menuItemOne]
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
