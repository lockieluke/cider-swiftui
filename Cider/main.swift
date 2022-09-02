//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import AppKit
import SwiftUI
import JavaScriptCore

class AppDelegate : NSObject, NSApplicationDelegate {
    
    private var appWindow: AppWindow!
    private var appMenu: AppMenu!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        self.appWindow = AppWindow()
        self.appMenu = AppMenu(appWindow.getWindow())
        NSApp.mainMenu = appMenu.getMenu()
        
        appWindow.show()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if (!flag) {
            appWindow.show()
        }
        
        return true
    }
    
}

autoreleasepool {
    let delegate = AppDelegate()
    NSApplication.shared.delegate = delegate
    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
}
