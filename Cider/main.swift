//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseAnalytics
import SwiftyUtils
import SwiftUI

#if canImport(AppKit)
import AppKit
public typealias ViewRepresentable = NSViewRepresentable
public typealias ApplicationDelegate = NSApplicationDelegate
public typealias Application = NSApplication
public typealias PlatformColor = NSColor
#elseif canImport(UIKit)
import UIKit
public typealias ViewRepresentable = UIViewRepresentable
public typealias ApplicationDelegate = UIApplicationDelegate
public typealias Application = UIApplication
public typealias PlatformColor = UIColor
#endif

class AppDelegate : NSObject, ApplicationDelegate {
    
#if os(macOS)
    private var appWindow: AppWindow!
    private var discordRPCModal: DiscordRPCModal!
    private var nativeUtilsWrapper: NativeUtilsWrapper!
#endif
    
    private func commonEntryPoint() {
        FirebaseConfiguration.shared.setLoggerLevel(.min)
#if DEBUG
        Analytics.setAnalyticsCollectionEnabled(false)
#endif
        FirebaseApp.configure()
    }
    
#if canImport(AppKit)
    func applicationDidFinishLaunching(_ notification: Notification) {
        self.commonEntryPoint()
        let discordRPCModal = DiscordRPCModal()
        let nativeUtilsWrapper = NativeUtilsWrapper()
        let appWindow = AppWindow(discordRPCModal: discordRPCModal, nativeUtilsWrapper: nativeUtilsWrapper)
        
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
        
        self.appWindow = appWindow
    }
#elseif canImport(UIKit)
    class SceneDelegate: NSObject, UIWindowSceneDelegate {
        
        var window: UIWindow?
        
        private var screen: UIScreen!
        
        private let appWindowModal = AppWindowModal()
        private var ciderPlayback: CiderPlayback!
        private var mkModal: MKModal!
        
        func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
            guard let windowScene = (scene as? UIWindowScene) else { return }
            
            let ciderPlayback = CiderPlayback(appWindowModal: appWindowModal)
            let mkModal = MKModal(ciderPlayback: ciderPlayback)
            
            let window = UIWindow(windowScene: windowScene)
            let contentView = ContentView()
                .environmentObject(self.appWindowModal)
                .environmentObject(ciderPlayback)
                .environmentObject(mkModal)
            window.rootViewController = UIHostingController(rootView: contentView)
            window.makeKeyAndVisible()
            
            self.screen = windowScene.screen
            
            self.window = window
            self.ciderPlayback = ciderPlayback
            self.mkModal = mkModal
        }
        
    }
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        
        self.commonEntryPoint()
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig: UISceneConfiguration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
#endif
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: Application) -> Bool {
        return false
    }
    
    func applicationSupportsSecureRestorableState(_ app: Application) -> Bool {
        return true
    }
    
#if canImport(AppKit)
    func applicationWillTerminate(_ notification: Notification) {
        terminateCXXNativeUtils()
#if os(macOS)
        self.discordRPCModal.agent.stop()
        self.appWindow.ciderPlayback.shutdownSync()
#endif
    }
#elseif canImport(UIKit)
    func applicationWillTerminate(_ application: UIApplication) {
        
    }
#endif
    
    
    #if os(macOS)
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
//        menu.addItem(Menu.wrapMenuItem(NSMenuItem(title: "Search", action: nil, keyEquivalent: "")))
        
        return menu
    }
    #endif
    
    func applicationShouldHandleReopen(_ sender: Application, hasVisibleWindows flag: Bool) -> Bool {
#if os(macOS)
        if (!flag) {
            self.appWindow.show()
        }
#endif
        
        return true
    }
    
}

autoreleasepool {
    let delegate = AppDelegate()
#if canImport(AppKit)
    Application.shared.delegate = delegate
    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
#elseif canImport(UIKit)
    UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
#endif
}
