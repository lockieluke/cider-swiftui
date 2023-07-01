//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftUI
#if canImport(AppKit)
import AppKit

extension NSColor {
    
    var hexString: String {
        let red = Int(round(self.redComponent * 0xFF))
        let green = Int(round(self.greenComponent * 0xFF))
        let blue = Int(round(self.blueComponent * 0xFF))
        let hexString = NSString(format: "#%02X%02X%02X", red, green, blue)
        return hexString as String
    }
    
}
#elseif canImport(UIKit)
import UIKit

extension UIColor {
    
    
}
#endif

extension Color {
    
    init(platformColor: PlatformColor) {
        #if canImport(AppKit)
        self.init(nsColor: platformColor)
        #elseif canImport(UIKit)
        self.init(uiColor: platformColor)
        #endif
    }
    
}
