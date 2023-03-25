//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Preferences
import InjectHotReload
import Defaults

struct DeveloperPreferencesPane: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    @Default(.debugOpenWebInspectorAutomatically) var openWebInspectorAutomatically
    
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
                            
                            Toggle("When CiderPlaybackAgent is launched, open Web Inspector automatically", isOn: $openWebInspectorAutomatically)
                                .toggleStyle(.checkbox)
                            Text("This setting will apply next time \(Bundle.main.displayName) is launched")
                                .preferenceDescription()
                            
                            HStack(alignment: .center) {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 7, height: 7)
                                
                                if ciderPlayback.isReady {
                                    VStack(alignment: .leading) {
                                        Text("CiderPlaybackAgent is active on port \(Text(verbatim: "\(Int(ciderPlayback.agentPort))")) with Session ID")
                                        
                                        Text(ciderPlayback.agentSessionId)
                                            .foregroundColor(.blue)
                                            .modifier(BasicHoverModifier())
                                            .onTapGesture {
                                                NSPasteboard.general.declareTypes([.string], owner: nil)
                                                NSPasteboard.general.setString(ciderPlayback.agentSessionId, forType: .string)
                                            }
                                    }
                                    .padding(.leading, 3)
                                }
                            }
                            .padding(.vertical)
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
                .transparentScrollbars()
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
