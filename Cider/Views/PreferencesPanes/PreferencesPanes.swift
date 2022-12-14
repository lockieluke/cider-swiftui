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

struct PrefValueField: View {
    
    @ObservedObject private var iO = Inject.observer
    
    var label: String
    var value: String
    
    init(_ label: String, _ value: String) {
        self.label = label
        self.value = value
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Text("\(label): ")
            Text(value).foregroundColor(.blue).modifier(BasicHoverModifier())
                .onTapGesture {
                    NSPasteboard.general.declareTypes([.string], owner: nil)
                    NSPasteboard.general.setString(value, forType: .string)
                }
        }
        .padding(.top)
        .enableInjection()
    }
    
}

struct PrefSectionText: View {
    
    @ObservedObject private var iO = Inject.observer
    
    var title: String
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        Text(title)
            .bold()
            .padding(.vertical, 3)
            .enableInjection()
    }
    
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
    
    
    static let DeveloperPreferencesViewController: (_ mkModal: MKModal, _ prefModal: PrefModal) -> PreferencePane = { mkModal, prefModal in
        let paneView = Preferences.Pane(
            identifier: .developer,
            title: "Developer",
            toolbarIcon: NSImage(systemSymbolName: "wrench.and.screwdriver.fill", accessibilityDescription: "Developer Preferences")!
        ) {
            DeveloperPreferencesPane()
                .environmentObject(mkModal)
                .environmentObject(prefModal)
        }
        
        return Preferences.PaneHostingController(pane: paneView)
    }
    
}
