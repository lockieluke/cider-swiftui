//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import AppKit
import Preferences

class AppMenu {
    
    private let menu: NSMenu
    private let appName: String
    private let window: NSWindow
    private let mkModal: MKModal
    private let authWorker: AuthWorker
    private let wsModal: WSModal
    private let ciderPlayback: CiderPlayback
    private let appWindowModal: AppWindowModal
    
    init(_ window: NSWindow, mkModal: MKModal, authWorker: AuthWorker, wsModal: WSModal, ciderPlayback: CiderPlayback, appWindowModal: AppWindowModal) {
        let menu = NSMenu()
        
        self.window = window
        self.appName = ProcessInfo.processInfo.processName
        self.menu = menu
        self.mkModal = mkModal
        self.authWorker = authWorker
        self.wsModal = wsModal
        self.ciderPlayback = ciderPlayback
        self.appWindowModal = appWindowModal
    }
    
    func loadMenus() {
        let undoManager = window.undoManager
        
        let appNameMenu = NSMenuItem()
        appNameMenu.submenu = NSMenu(title: "\(appName)")
        
        // Preferences is renamed to Settings starting on macOS Ventura
        var preferencesName = "Preferences..."
        if #available(macOS 13.0, *) {
            preferencesName = "Settings..."
        }   
        
        let preferencesMenu = NSMenuItem(title: preferencesName, action: #selector(self.showPreferences(_:)), keyEquivalent: ",")
        preferencesMenu.target = self
        
        let signOutMenu = NSMenuItem(title: "Sign Out...", action: #selector(self.signOut(_:)), keyEquivalent: "")
        signOutMenu.target = self
        
        let hideOthersMenu = NSMenuItem(title: NSLocalizedString("Hide Other", comment: ""), action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersMenu.keyEquivalentModifierMask = [.command, .option]
        
        appNameMenu.submenu?.items = [
            NSMenuItem(title: String.localizedStringWithFormat(NSLocalizedString("About %@", comment: ""), ProcessInfo.processInfo.processName), action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""),
            .separator(),
            preferencesMenu,
            .separator(),
            hideOthersMenu,
            NSMenuItem(title: String.localizedStringWithFormat(NSLocalizedString("Hide %@", comment: ""), ProcessInfo.processInfo.processName), action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"),
            NSMenuItem(title: NSLocalizedString("Show All", comment: ""), action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""),
            .separator(),
            signOutMenu,
            NSMenuItem(title: String.localizedStringWithFormat(NSLocalizedString("Quit %@", comment: ""), ProcessInfo.processInfo.processName), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        ]
        
        let fileMenu = NSMenuItem()
        fileMenu.submenu = NSMenu(title: "File")
        fileMenu.submenu?.items = [
            NSMenuItem(title: NSLocalizedString("Close Window", comment: ""), action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
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
        
        #if DEBUG
        let developerMenu = NSMenuItem()
        developerMenu.submenu = NSMenu(title: "Developer")
        developerMenu.submenu?.items = [
            wrapMenuItem(NSMenuItem(title: "Open WebSockets Debugger", action: #selector(self.openWSDebugger(_:)), keyEquivalent: ""))
        ]
        #endif
        
        let windowMenu = NSMenuItem()
        windowMenu.submenu = NSMenu(title: "Window")
        windowMenu.submenu?.items = [
            NSMenuItem(title: NSLocalizedString("Minimise", comment: ""), action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: ""),
            NSMenuItem(title: NSLocalizedString("Zoom", comment: ""), action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        ]
        
        let helpMenu = NSMenuItem()
        let helpMenuSearch = NSMenuItem()
        helpMenuSearch.view = NSTextField()
        helpMenu.submenu = NSMenu(title: "Help")
        
        let discordMenu = NSMenuItem(title: "Open Discord", action: #selector(self.openDiscord(_:)), keyEquivalent: "")
        discordMenu.target = self
        
        let githubMenu = NSMenuItem(title: "Open GitHub", action: #selector(self.openOrgGitHub(_:)), keyEquivalent: "")
        githubMenu.target = self
        
        helpMenu.submenu?.items = [
            helpMenuSearch,
            discordMenu,
            githubMenu
        ]
        
        #if DEBUG
        menu.items = [appNameMenu, fileMenu, editMenu, developerMenu, windowMenu, helpMenu]
        #else
        menu.items = [appNameMenu, fileMenu, editMenu, windowMenu, helpMenu]
        #endif
    }
    
    func wrapMenuItem(_ menuItem: NSMenuItem) -> NSMenuItem {
        menuItem.target = self
        return menuItem
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
    
    @objc func showPreferences(_ sender: Any) {
        PreferencesWindowController(
            preferencePanes: [
                PreferencesPanes.GeneralPreferenceViewController(),
                PreferencesPanes.AudioPreferencesViewController(
                    self.ciderPlayback
                ),
                PreferencesPanes.DeveloperPreferencesViewController(
                    self.mkModal,
                    self.ciderPlayback
                )
            ],
            style: .toolbarItems,
            animated: true,
            hidesToolbarForSingleItem: false
        ).show()
    }
    
    @objc func openDiscord(_ sender: Any) {
        Support.openDiscord()
    }
    
    @objc func openOrgGitHub(_ sender: Any) {
        Support.openOrgGitHub()
    }
    
    @objc func openWSDebugger(_ sender: Any) {
        let wsDebugger = WSDebugger(
            wsModal: self.wsModal,
            ciderPlayback: self.ciderPlayback,
            appWindowModal: self.appWindowModal
        )
        wsDebugger.open()
    }
    
    func getMenu() -> NSMenu {
        return self.menu
    }
    
}
