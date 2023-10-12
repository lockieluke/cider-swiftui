//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import Foundation
#if canImport(AppKit)
import AppKit
import Settings
import SwiftUI
import WebKit

class AppMenu {
    
    let menu: NSMenu
    private let appName: String
    private let window: NSWindow
    private let settingsWindowController: SettingsWindowController
    private let mkModal: MKModal
    private let authModal: AuthModal
    private let wsModal: WSModal
    private let ciderPlayback: CiderPlayback
    private let appWindowModal: AppWindowModal
    private let nativeUtilsWrapper: NativeUtilsWrapper
    private let cacheModal: CacheModal
    private let connectModal: ConnectModal
    private let navigationModal: NavigationModal
    
    private var hasPreviouslyOpenedPlayground: Bool = false
    private var playgroundWindowDelegate: NSWindowDelegate!
    
    init(_ window: NSWindow, mkModal: MKModal, authModal: AuthModal, wsModal: WSModal, ciderPlayback: CiderPlayback, appWindowModal: AppWindowModal, nativeUtilsWrapper: NativeUtilsWrapper, cacheModal: CacheModal, connectModal: ConnectModal, navigationModal: NavigationModal) {
        let menu = NSMenu()
        
        #if DEBUG
        let additionalPanes = [
            PreferencesPanes.DeveloperPreferencesViewController(
                mkModal,
                ciderPlayback
            )
        ]
        #else
        let additionalPanes: [SettingsPane] = []
        #endif
        
        self.settingsWindowController = SettingsWindowController(
            panes: [
                PreferencesPanes.GeneralPreferenceViewController(cacheModal),
                PreferencesPanes.AccountPreferencesViewController(connectModal),
                PreferencesPanes.AudioPreferencesViewController(
                    ciderPlayback
                )
            ] + additionalPanes,
            style: .toolbarItems,
            animated: true,
            hidesToolbarForSingleItem: false
        )
        
        self.window = window
        self.appName = ProcessInfo.processInfo.processName
        self.menu = menu
        self.mkModal = mkModal
        self.authModal = authModal
        self.wsModal = wsModal
        self.ciderPlayback = ciderPlayback
        self.appWindowModal = appWindowModal
        self.nativeUtilsWrapper = nativeUtilsWrapper
        self.cacheModal = cacheModal
        self.connectModal = connectModal
        self.navigationModal = navigationModal
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
            NSMenuItem(title: "Quit \(ProcessInfo.processInfo.processName)", action: #selector(self.terminate(_:)), keyEquivalent: "q")
        ]
        
        let fileMenu = NSMenuItem().then {
            $0.submenu = NSMenu(title: "File")
            $0.submenu?.items = [
                NSMenuItem(title: NSLocalizedString("Close Window", comment: ""), action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
            ]
        }
        
        let editMenu = NSMenuItem().then {
            $0.submenu = NSMenu(title: "Edit")
            $0.submenu?.items = [
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
        }
        
        let viewMenu = NSMenuItem().then {
            $0.submenu = NSMenu(title: "View").then {
                $0.items = [
                    NSMenuItem(title: "Toggle Sidebar", action: #selector(self.toggleSidebar(_:)), keyEquivalent: "s").then { $0.target = self }
                ]
            }
        }
        
#if DEBUG
        let developerMenu = NSMenuItem().then {
            $0.submenu = NSMenu(title: "Developer")
            $0.submenu?.items = [
                NSMenuItem(title: "Open WebSockets Debugger", action: #selector(self.openWSDebugger(_:)), keyEquivalent: "").then { $0.target = self },
                NSMenuItem(title: "Open CiderPlaybackAgent debugger", action: #selector(self.openInspector(_:)), keyEquivalent: "").then { $0.target = self },
                NSMenuItem(title: "Show Donation View", action: #selector(self.showDonationView(_:)), keyEquivalent: "").then { $0.target = self },
                NSMenuItem(title: "Playground...", action: #selector(self.openPlaygrounds(_:)), keyEquivalent: "\\").then { $0.target = self },
                .separator(),
                NSMenuItem(title: "Clear WebKit cache", action: #selector(self.clearWebViewCache(_:)), keyEquivalent: "").then { $0.target = self }
            ]
            $0.target = self
        }
#endif
        
        let windowMenu = NSMenuItem().then {
            $0.submenu = NSMenu(title: "Window")
            $0.submenu?.items = [
                NSMenuItem(title: NSLocalizedString("Minimise", comment: ""), action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: ""),
                NSMenuItem(title: NSLocalizedString("Zoom", comment: ""), action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
            ]
        }
        
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
        menu.items = [appNameMenu, fileMenu, editMenu, viewMenu, developerMenu, windowMenu, helpMenu]
#else
        menu.items = [appNameMenu, fileMenu, editMenu, viewMenu, windowMenu, helpMenu]
#endif
    }
    
    @objc func signOut(_ sender: Any) {
        Task {
            Logger.shared.info("Signing out")
            await self.authModal.clearAuthCache()
            await self.mkModal.resetAuthorisation()
            DispatchQueue.main.async {
                Alert.showModal(on: self.window, message: "Cider will have to be restarted so we can sign you out") {
                    NSApp.relaunch(clearAppData: true)
                }
            }
        }
    }
    
    @objc func showPreferences(_ sender: Any) {
        self.settingsWindowController.show()
    }
    
    @objc func openDiscord(_ sender: Any) {
        Support.openDiscord()
    }
    
    @objc func openOrgGitHub(_ sender: Any) {
        Support.openOrgGitHub()
    }
    
    @objc func toggleSidebar(_ sender: Any) {
        withAnimation(.interactiveSpring()) {
            self.navigationModal.showSidebar.toggle()
        }
    }
    
    @objc func showDonationView(_ sender: Any) {
        self.navigationModal.isDonateViewPresent = true
    }
    
#if DEBUG
    @objc func openWSDebugger(_ sender: Any) {
        let wsDebugger = WSDebugger(
            wsModal: self.wsModal,
            ciderPlayback: self.ciderPlayback,
            appWindowModal: self.appWindowModal
        )
        wsDebugger.open()
    }
    
    @objc func clearWebViewCache(_ sender: Any) {
        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) {
            Logger.shared.info("Successfully cleared WebKit cache")
        }
    }
    
    @objc func openPlaygrounds(_ sender: Any) {
        if hasPreviouslyOpenedPlayground {
            return
        }
        
        typealias TestAction = CiderPlayground.CiderPlaygroundTestAction
        let activeScreen = NSScreen.activeScreen
        
        
        let ciderPlayground = CiderPlayground(testActions: [
            TestAction(name: "Fetch Browse Data", description: "Fetch browse storefront data and parse JSON", action: {
                if (self.mkModal.isAuthorised) {
                    return await self.mkModal.AM_API.fetchBrowse()
                }
                
                return nil
            }),
            TestAction(name: "Fetch latest User Agent", description: "Fetch latest User Agent for WKWebView", action: {
                return await Networking.findLatestWebViewUA()
            }),
            TestAction(name: "Remove UA Cache", description: "Remove latest User Agent from cache", action: {
                Networking.clearUserAgentCache()
                return nil
            })
        ])
            .frame(minWidth: 800, minHeight: 600)
            .environmentObject(self.mkModal)
        let playgroundWindow = NSWindow(contentRect: NSRect(x: .zero, y: .zero, width: 800, height: 600), styleMask: [.closable, .resizable, .titled, .fullSizeContentView], backing: .buffered, defer: false).then {
            $0.collectionBehavior = $0.collectionBehavior.union(.fullScreenNone)
            $0.contentViewController = NSHostingController(rootView: ciderPlayground)
            $0.titlebarAppearsTransparent = true
            $0.titleVisibility = .hidden
            $0.isMovableByWindowBackground = true
            $0.isOpaque = false
            $0.backgroundColor = .clear
            $0.title = "Cider Playground"
            
            let toolbar = NSToolbar()
            $0.showsToolbarButton = false
            $0.toolbar = toolbar
            
            class PlaygroundWindowDelegate: NSObject, NSWindowDelegate {
                
                weak var parent: AppMenu! = nil
                
                init(parent: AppMenu) {
                    self.parent = parent
                }
                
                func windowWillClose(_ notification: Notification) {
                    self.parent.hasPreviouslyOpenedPlayground = false
                }
            }
            
            let delegate = PlaygroundWindowDelegate(parent: self)
            $0.delegate = delegate
            self.playgroundWindowDelegate = delegate
            
            var pos = NSPoint()
            pos.x = activeScreen.visibleFrame.midX
            pos.y = activeScreen.visibleFrame.midY
            $0.setFrameOrigin(pos)
            $0.isReleasedWhenClosed = false
            $0.center()
        }
        
        playgroundWindow.makeKeyAndOrderFront(sender)
        self.hasPreviouslyOpenedPlayground = true
    }
    
    @objc func openInspector(_ sender: Any) {
        Task {
            await self.ciderPlayback.openInspector()
        }
    }
#endif
    
    @objc func terminate(_ sender: Any) {
        print("Terminating")
        NSApp.terminate(nil)
        print("Terminated")
    }
    
}

#endif
