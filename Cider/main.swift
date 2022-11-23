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
        
        // might be useful for cleaning up child processes when process gets killed
        let terminatedCallback = { exitCode in
            Logger.shared.info("Cider is exiting")
            DispatchQueue.main.async {
                CiderPlayback.shared.shutdownSync()
            }
        } as (@convention(c) (Int32) -> Void)?
        signal(SIGTERM, terminatedCallback)
        signal(SIGINT, terminatedCallback)
        signal(SIGKILL, terminatedCallback)
        signal(SIGSTOP, terminatedCallback)
        
        appWindow.show()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        self.ciderPlayback.shutdownSync()
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
