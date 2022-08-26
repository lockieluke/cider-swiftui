//
//  main.swift
//  Cider
//
//  Created by Sherlock LUK on 26/08/2022.
//

import Foundation
import AppKit
import SwiftUI

class AppDelegate : NSObject, NSApplicationDelegate {
    
    private var appWindow: AppWindow!
    private var appMenu: AppMenu!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        self.appMenu = AppMenu()
        NSApp.mainMenu = appMenu
        self.appWindow = AppWindow()
        
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
