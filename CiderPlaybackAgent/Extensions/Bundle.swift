//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation

extension Bundle {
    var procName: String {
        return Bundle.main.executableURL?.lastPathComponent ?? "Could not load process name"
    }
}
