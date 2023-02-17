//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseAnalytics
import AppKit
import SwiftUI
import Watchdog

class AppDelegate : NSObject, NSApplicationDelegate {
    
    private var appWindow: AppWindow!
    private var watchdog: Watchdog!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        #if DEBUG
        if CommandLine.arguments.contains("--enable-watchdog") {
            self.watchdog = Watchdog(threshold: 1.0, strictMode: true)
        }
        #endif
        
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        #if DEBUG
        Analytics.setAnalyticsCollectionEnabled(false)
        #endif
        FirebaseApp.configure()
        
        self.appWindow = AppWindow()
        
        // might be useful for cleaning up child processes when process gets killed
        let terminatedCallback = { exitCode in
            Logger.shared.info("Cider is exiting")
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
        self.appWindow.ciderPlayback.shutdownSync()
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
