//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
#if canImport(Settings)
import Settings
#endif
import Inject

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
                    NativeUtilsWrapper.nativeUtilsGlobal.copy_string_to_clipboard(value)
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
    
    static let GeneralPreferenceViewController: (_ cacheModal: CacheModal, _ navigationModal: NavigationModal) -> SettingsPane = { cacheModal, navigationModal in
        let paneView = Settings.Pane(
            identifier: .general,
            title: "General",
            toolbarIcon: NSImage(systemSymbol: .gearshape, accessibilityDescription: "General Preferences")
        ) {
            GeneralPreferencesPane()
                .environmentObject(cacheModal)
                .environmentObject(navigationModal)
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    
    static let AccountPreferencesViewController: (_ connectModal: ConnectModal) -> SettingsPane = { connectModal in
        let paneView = Settings.Pane(
            identifier: .account,
            title: "Connect",
            toolbarIcon: NSImage(systemSymbol: .personCircle, accessibilityDescription: "Cider Connect Preferences")
        ) {
            AccountPreferencesPane()
                .environmentObject(connectModal)
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    
    #if DEBUG
    static let DeveloperPreferencesViewController: (_ mkModal: MKModal, _ ciderPlayback: CiderPlayback) -> SettingsPane = { mkModal, ciderPlayback in
        let paneView = Settings.Pane(
            identifier: .developer,
            title: "Developer",
            toolbarIcon: NSImage(systemSymbol: .wrenchAndScrewdriverFill, accessibilityDescription: "Developer Preferences")
        ) {
            DeveloperPreferencesPane()
                .environmentObject(mkModal)
                .environmentObject(ciderPlayback)
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    #endif
    
    static let AudioPreferencesViewController: (_ ciderPlayback: CiderPlayback) -> SettingsPane = { ciderPlayback in
        let paneView = Settings.Pane(
            identifier: .audio,
            title: "Audio",
            toolbarIcon: NSImage(systemSymbol: .waveform, accessibilityDescription: "Audio Preferences")
        ) {
            AudioPreferencesPane()
                .environmentObject(ciderPlayback)
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    
}
