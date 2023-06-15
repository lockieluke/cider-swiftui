//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import FirebaseCore
import FirebaseAnalytics
import SwiftyUtils

class AppDelegate : NSObject, NSApplicationDelegate {
    
    private var appWindow: AppWindow!
    private var discordRPCModal: DiscordRPCModal!
    private var nativeUtilsWrapper: NativeUtilsWrapper!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseConfiguration.shared.setLoggerLevel(.min)
#if DEBUG
        Analytics.setAnalyticsCollectionEnabled(false)
#endif
        FirebaseApp.configure()
      
        let discordRPCModal = DiscordRPCModal()
        let nativeUtilsWrapper = NativeUtilsWrapper()
        self.appWindow = AppWindow(discordRPCModal: discordRPCModal, nativeUtilsWrapper: nativeUtilsWrapper)
        
        // might be useful for cleaning up child processes when process gets killed
        let terminatedCallback = { exitCode in
            Logger.shared.info("Cider is exiting")
        } as (@convention(c) (Int32) -> Void)?
        signal(SIGTERM, terminatedCallback)
        signal(SIGINT, terminatedCallback)
        signal(SIGKILL, terminatedCallback)
        signal(SIGSTOP, terminatedCallback)
        
        self.discordRPCModal = discordRPCModal
        self.nativeUtilsWrapper = nativeUtilsWrapper
        appWindow.show()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        terminateCXXNativeUtils()
        self.discordRPCModal.agent.stop()
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
