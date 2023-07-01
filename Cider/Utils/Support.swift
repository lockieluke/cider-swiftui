//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

class Support {
    
    static func openDiscord() {
        URL(string: "https://discord.com/invite/applemusic")!.open()
    }
    
    static func openCiderGitHub() {
        #if DEBUG
        URL(string: "https://github.com/ciderapp/project2-swiftui")!.open()
        #endif
    }
    
    static func openOrgGitHub() {
        URL(string: "https://github.com/ciderapp/")!.open()
    }
    
}
