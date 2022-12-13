//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import AppKit

class Support {
    
    static func openDiscord() {
        NSWorkspace.shared.open(URL(string: "https://discord.com/invite/applemusic")!)
    }
    
    static func openCiderGitHub() {
        #if DEBUG
        NSWorkspace.shared.open(URL(string: "https://github.com/ciderapp/project2-swiftui")!)
        #endif
    }
    
    static func openOrgGitHub() {
        NSWorkspace.shared.open(URL(string: "https://github.com/ciderapp/")!)
    }
    
}
