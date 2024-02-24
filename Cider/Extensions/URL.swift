//
//  URL.swift
//  Cider
//
//  Created by Sherlock LUK on 27/06/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

extension URL {
    
    func open() {
        #if canImport(AppKit)
        NSWorkspace.shared.open(self)
        #elseif canImport(UIKit)
        UIApplication.shared.open(self)
        #endif
    }
    
    func openInRegularArcWindow() {
        let script = NSAppleScript(source: """
tell application "Arc"
    if (count of windows) is 0 then
        make new window
    end if
    
    tell front window
        make new tab with properties {URL:"\(self.absoluteString)"}
    end tell
    
    activate
end tell
""")
        
        var errorDict: NSDictionary? = nil
        script?.executeAndReturnError(&errorDict)
        if let error = errorDict {
            print("Error opening URL in regular Arc window: \(error), falling back to opening using URL.open")
            self.open()
        }
    }
    
}
