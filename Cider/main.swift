//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import AppKit
import SwiftUI

class AppDelegate : NSObject, NSApplicationDelegate {
    
    private var appWindow: AppWindow!
    private var appMenu: AppMenu!
    private let ciderPlayback = CiderPlayback.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        self.appWindow = AppWindow()
        self.appMenu = AppMenu(appWindow.getWindow())
        appMenu.loadMenus()
        NSApp.mainMenu = appMenu.getMenu()
        
        appWindow.show()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            await self.ciderPlayback.shutdown()
            semaphore.signal()
        }
        semaphore.wait()
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
