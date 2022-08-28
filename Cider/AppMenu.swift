//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import AppKit

class AppMenu {
    
    private let menu: NSMenu
    
    init(_ window: NSWindow) {
        let menu = NSMenu()
        let undoManager = window.undoManager
        
        let appName = ProcessInfo.processInfo.processName
        let appNameMenu = NSMenuItem()
        appNameMenu.submenu = NSMenu(title: "\(appName)")
        appNameMenu.submenu?.items = [NSMenuItem(title: "Quit \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")]
        
        let editMenu = NSMenuItem()
        editMenu.submenu = NSMenu(title: "Edit")
        editMenu.submenu?.items = [
            NSMenuItem(title: undoManager?.undoMenuItemTitle ?? "Undo", action: Selector(("undo:")), keyEquivalent: "z"),
            NSMenuItem(title: undoManager?.redoMenuItemTitle ?? "Redo", action: Selector(("redo:")), keyEquivalent: "Z"),
            .separator(),
            NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"),
            NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"),
            NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"),
            NSMenuItem.separator(),
            NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)),
                                              keyEquivalent: "a")
        ]
        
        menu.items = [appNameMenu, editMenu]
        self.menu = menu
    }
    
    func getMenu() -> NSMenu {
        return self.menu
    }
    
}
