//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation

extension Bundle {
    
    var displayName: String {
        return (object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ?? ProcessInfo.processInfo.processName
    }
    
    var version: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
    
}
