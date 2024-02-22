//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseAnalytics
import GoogleSignIn
import SwiftyUtils
import SwiftUI
import SFSafeSymbols

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

#if DEBUG
import Atlantis
import Defaults
#endif

class AppDelegate : NSObject, ApplicationDelegate {
    
#if os(macOS)
    private var appWindow: AppWindow!
    private var nativeUtilsWrapper: NativeUtilsWrapper!
#endif
    
    private func commonEntryPoint() {
#if DEBUG
        if Defaults[.enableAtlantis] {
            Atlantis.start()
        }
#endif
        
        FirebaseConfiguration.shared.setLoggerLevel(.min)
#if DEBUG
        FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(false)
#endif
        FirebaseApp.configure()
    }
    
#if canImport(AppKit)
    func applicationDidFinishLaunching(_ notification: Notification) {
        Analytics.shared.startSentry()
        
        self.commonEntryPoint()
        
        let appleEventManager: NSAppleEventManager = NSAppleEventManager.shared()
        appleEventManager.setEventHandler(self, andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
        
        Networking.initialise()
        
        let nativeUtilsWrapper = NativeUtilsWrapper()
        let appWindow = AppWindow(nativeUtilsWrapper: nativeUtilsWrapper)
        
        // might be useful for cleaning up child processes when process gets killed
        let terminatedCallback: sig_t = { exitCode in
            Logger.shared.info("Cider is exiting")
            ElevationHelper.shared.terminate()
            UpdateHelper.shared.terminate()
            exit(exitCode)
        }
        signal(SIGTERM, terminatedCallback)
        signal(SIGINT, terminatedCallback)
        signal(SIGKILL, terminatedCallback)
        signal(SIGSTOP, terminatedCallback)
        
        ElevationHelper.shared.start()
        UpdateHelper.shared.start()
        
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
        let sceneConfig: UISceneConfiguration = UISceneConfiguration(title: nil, sessionRole: connectingSceneSession.role)
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
#if os(macOS)
        self.appWindow.ciderPlayback.shutdown()
        ElevationHelper.shared.terminate()
        UpdateHelper.shared.terminate()
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
    
    func application(_ application: NSApplication, open urls: [URL]) {
        
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
    
    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent: NSAppleEventDescriptor) {
        if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue, let url = URL(string: urlString) {
            //            GIDSignIn.sharedInstance.handle(url)
            
            if let scheme = url.scheme, scheme.caseInsensitiveCompare("cider-swiftui") == .orderedSame {
                if let host = url.host {
                    switch host {
                    case "analytics-learn-more":
                        self.appWindow.navigationModal.isAnalyticsPersuationPresent = true
                        break
                        
                    default:
                        break
                    }
                }
            }
        }
    }
    
}

autoreleasepool {
#if DEBUG
    NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.johnholdsworth.InjectionIII")?.open()
#endif
    let delegate = AppDelegate()
#if canImport(AppKit)
    Application.shared.delegate = delegate
    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
#elseif canImport(UIKit)
    UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
#endif
}
