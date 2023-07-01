//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

class Alert {
    
    #if canImport(AppKit)
    static func showModal(on window: NSWindow, message: String, icon: NSAlert.Style = .informational, completion: (() -> Void)? = nil) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .informational
        alert.beginSheetModal(for: window) { _ in
            completion?()
        }
    }
    #elseif canImport(UIKit)
    static func showModal(message: String, style: UIAlertController.Style = .alert, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: style)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        UIApplication.topViewController()?.present(alert, animated: true, completion: {
            completion?()
        })
    }
    #endif
    
}
