//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation

extension Bundle {
    var displayName: String {
        return (object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ?? ProcessInfo.processInfo.processName
    }
}
