//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import AppKit

extension NSApplication {
    
    func relaunch(clearAppData: Bool = false) {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
        
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", "sleep \(0.2);\(clearAppData ? " rm -rf \"\(NSHomeDirectory())/Library/WebKit/\(bundleIdentifier)\";" : "") sleep \(0.8); open \"\(Bundle.main.bundlePath)\""]
        task.launch()
        
        NSApp.terminate(self)
        exit(0)
    }
    
}
