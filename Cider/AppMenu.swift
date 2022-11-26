//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import AppKit

class AppMenu {
    
    private let menu: NSMenu
    private let appName: String
    private let window: NSWindow
    private let mkModal: MKModal
    private let authWorker: AuthWorker
    
    init(_ window: NSWindow, mkModal: MKModal, authWorker: AuthWorker) {
        let menu = NSMenu()
        
        self.window = window
        self.appName = ProcessInfo.processInfo.processName
        self.menu = menu
        self.mkModal = mkModal
        self.authWorker = authWorker
    }
    
    func loadMenus() {
        let undoManager = window.undoManager
        
        let appNameMenu = NSMenuItem()
        appNameMenu.submenu = NSMenu(title: "\(appName)")
        
        let signOutMenu = NSMenuItem(title: "Sign Out...", action: #selector(self.signOut(_:)), keyEquivalent: "")
        signOutMenu.target = self
        
        appNameMenu.submenu?.items = [
            signOutMenu,
            .separator(),
            NSMenuItem(title: "Quit \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        ]
        
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
    }
    
    @objc func signOut(_ sender: Any) {
        Task {
            Logger.shared.info("Signing out")
            await AuthWorker.clearAuthCache()
            self.mkModal.resetAuthorisation()
            DispatchQueue.main.async {
                Alert.showModal(on: self.window, message: "Cider will have to be restarted so we can sign you out") {
                    NSApp.relaunch(clearAppData: true)
                }
            }
        }
    }
    
    func getMenu() -> NSMenu {
        return self.menu
    }
    
}
