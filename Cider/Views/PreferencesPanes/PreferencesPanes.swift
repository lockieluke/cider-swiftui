//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Settings
import InjectHotReload

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
    
    static let GeneralPreferenceViewController: () -> SettingsPane = {
        let paneView = Settings.Pane(
            identifier: .general,
            title: "General",
            toolbarIcon: NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General Preferences")!
        ) {
            GeneralPreferencesPane()
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    
    
    static let DeveloperPreferencesViewController: (_ mkModal: MKModal, _ ciderPlayback: CiderPlayback) -> SettingsPane = { mkModal, ciderPlayback in
        let paneView = Settings.Pane(
            identifier: .developer,
            title: "Developer",
            toolbarIcon: NSImage(systemSymbolName: "wrench.and.screwdriver.fill", accessibilityDescription: "Developer Preferences")!
        ) {
            DeveloperPreferencesPane()
                .environmentObject(mkModal)
                .environmentObject(ciderPlayback)
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    
    static let AudioPreferencesViewController: (_ ciderPlayback: CiderPlayback) -> SettingsPane = { ciderPlayback in
        let paneView = Settings.Pane(
            identifier: .audio,
            title: "Audio",
            toolbarIcon: NSImage(systemSymbolName: "waveform", accessibilityDescription: "Audio Preferences")!
        ) {
            AudioPreferencesPane()
                .environmentObject(ciderPlayback)
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    
}
