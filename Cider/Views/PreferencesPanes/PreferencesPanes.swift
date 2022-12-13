//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Preferences
import InjectHotReload

extension Preferences.PaneIdentifier {
    static let general = Self("general")
    static let developer = Self("developer")
}

struct PreferencesPanes {
    
    static let GeneralPreferenceViewController: () -> PreferencePane = {
        let paneView = Preferences.Pane(
            identifier: .general,
            title: "General",
            toolbarIcon: NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General Preferences")!
        ) {
            GeneralPreferencesPane()
        }
        
        return Preferences.PaneHostingController(pane: paneView)
    }
    
    
    static let DeveloperPreferencesViewController: (_ mkModal: MKModal) -> PreferencePane = { mkModal in 
        let paneView = Preferences.Pane(
            identifier: .developer,
            title: "Developer",
            toolbarIcon: NSImage(systemSymbolName: "wrench.and.screwdriver.fill", accessibilityDescription: "Developer Preferences")!
        ) {
            DeveloperPreferencesPane()
                .environmentObject(mkModal)
        }
        
        return Preferences.PaneHostingController(pane: paneView)
    }
    
}
