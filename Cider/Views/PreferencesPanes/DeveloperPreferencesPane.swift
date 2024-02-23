//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

#if DEBUG
import SwiftUI
import Settings
import Inject
import Defaults
import Atlantis

struct DeveloperPreferencesPane: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    @Default(.debugOpenWebInspectorAutomatically) var openWebInspectorAutomatically
    @Default(.enableAtlantis) var enableAtlantis
    
    var body: some View {
        Settings.Container(contentWidth: 450.0) {
            Settings.Section(title: "") {
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
                                .settingDescription()
                                .padding(.vertical)
                        }
                        
                        Group {
                            PrefSectionText("Debugging Settings - Playback Engine (\(Defaults[.playbackBackend].rawValue))")
                            
                            Toggle("Open Playback Debugger automatically", isOn: $openWebInspectorAutomatically)
                                .toggleStyle(.checkbox)
                            Text("This setting will apply next time \(Bundle.main.displayName) is launched")
                                .settingDescription()
                        }
                        
                        Group {
                            PrefSectionText("Debugging Settings - Networking")
                            Toggle("Enable [Atlantis](https://github.com/ProxymanApp/atlantis) for easy HTTP requet interception", isOn: $enableAtlantis)
                            Text("This setting will apply next time \(Bundle.main.displayName) is launched")
                                .settingDescription()
                        }
                        
                        Group {
                            PrefSectionText("Diagnostic Information")
                            
                            Text("""
                            Processor: \(Diagnostic.cpuName)
                            Executation Environment: \(Diagnostic.processIsTranslatedStr)
                            Memory: \(ProcessInfo.processInfo.physicalMemory / 1024 / 1024 / 1024) GB
                            Serial Number: \(Diagnostic.macSerialNumber ?? "Unable to retrieve serial number")
                            OS: \(Diagnostic.macOSName) \(Diagnostic.macOSFullVersionString)
                            Cider: \(Bundle.main.appVersion)
                            """)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .transparentScrollbars()
            }
        }
        .onChange(of: enableAtlantis) { enableAtlantis in
            if !enableAtlantis {
                Atlantis.stop()
            }
        }
        .frame(height: 600)
        .enableInjection()
    }
    
}

struct DeveloperPreferencesPane_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperPreferencesPane()
    }
}

#endif
