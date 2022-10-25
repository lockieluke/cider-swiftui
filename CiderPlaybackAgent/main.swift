//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import Swifter
import Dispatch

class AppDelegate : NSObject, NSApplicationDelegate {
    
    private let server = HttpServer()
    private var musicKitWorker: MusicKitWorker?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        self.musicKitWorker = MusicKitWorker()
        
        server["/"] = { request in
            if !isReqFromCider(request.headers) {
                return .movedPermanently("https://discord.com/invite/applemusic")
            }
            
            return .ok(.text("HELLO WORLD"))
        }

        let defaultPort = Bundle.main.infoDictionary?["DEFAULT_PORT"] as! Int
        
        do {
            try server.start(UInt16(defaultPort))
        } catch {
            fatalError("\(Bundle.main.executableURL?.lastPathComponent ?? "This application encountered an error"): \(error)")
        }
    }
    
}

let appDelegate = AppDelegate()
autoreleasepool {
    NSApplication.shared.delegate = appDelegate
    NSApplication.shared.run()
}
