//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import AppKit

class Alert {
    
    static func showModal(on window: NSWindow, message: String, icon: NSAlert.Style = .informational, completion: (() -> Void)? = nil) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .informational
        alert.beginSheetModal(for: window) { _ in
            completion?()
        }
    }
    
}
