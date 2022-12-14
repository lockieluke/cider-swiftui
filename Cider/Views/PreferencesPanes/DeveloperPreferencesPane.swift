//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Preferences
import InjectHotReload

struct DeveloperPreferencesPane: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var prefModal: PrefModal
    
    var body: some View {
        Preferences.Container(contentWidth: 450.0) {
            Preferences.Section(title: "") {
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading) {
                        Group {
                            PrefSectionText("Debugging Information")
                            
                            if let developerToken = mkModal.AM_API.AM_TOKEN,
                               let userToken = mkModal.AM_API.AM_USER_TOKEN {
                                PrefValueField("MusicKit Developer Token", developerToken)
                                PrefValueField("MusicKit User Token", userToken)
                            }
                            
                            Text("Do not share this information with anyone.  The Cider Team would never, never ask for this.")
                                .foregroundColor(.red)
                                .preferenceDescription()
                                .padding(.vertical)
                        }
                        
                        Group {
                            PrefSectionText("Debugging Settings - CiderPlaybackAgent")
                            
                            Toggle("When CiderPlaybackAgent is launched, open Web Inspector automatically", isOn: $prefModal.prefs.openWebInspectorAutomatically)
                                .toggleStyle(.checkbox)
                            Text("This setting will apply next time \(Bundle.main.displayName) is launched")
                                .preferenceDescription()
                            
                        }
                        
                        Group {
                            PrefSectionText("Diagnostic Information")
                            
                            Text("""
                            Processor: \(Diagnostic.cpuName)
                            Executation Environment: \(Diagnostic.processIsTranslatedStr)
                            Memory: \(ProcessInfo.processInfo.physicalMemory / 1024 / 1024 / 1024) GB
                            Serial Number: \(Diagnostic.macSerialNumber ?? "Unable to retrieve serial number")
                            OS: \(Diagnostic.macOSName) \(Diagnostic.macOSFullVersionString)
                            Cider: \(Bundle.main.version)
                            """)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .enableInjection()
    }
    
}

struct DeveloperPreferencesPane_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperPreferencesPane()
    }
}
