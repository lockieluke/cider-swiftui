//
//  NSApplication.swift
//  Cider
//
//  Created by Sherlock LUK on 10/12/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import AppKit

extension NSApplication {
    
    var icon: NSImage? {
        guard let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? NSDictionary,
              let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? NSDictionary,
              let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? NSArray,
              // First will be smallest for the device class, last will be the largest for device class
              let lastIcon = iconFiles.lastObject as? String,
              let icon = NSImage(named: lastIcon) else {
            guard let iconName = Bundle.main.infoDictionary?["CFBundleIconName"] as? String, let cfIcon = NSImage(named: iconName) else {
                return nil
            }
            
            return cfIcon
        }
        
        return icon
    }
    
}
