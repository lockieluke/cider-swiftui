//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Settings
import Inject
import Throttler
import Defaults

struct AudioPreferencesPane: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    @State private var audioQuality: AudioQuality = .High
    
    var audioQualityDescription: String {
        get {
            switch self.audioQuality {
                
            case .Standard:
                return "Standard Quality contains less detail of the audio but can help save network bandwidth"
                
                
            case .High:
                return "High Quality contains more detail of the audio but consumes more network bandwidth"
                
            }
        }
    }
    
    var body: some View {
        Settings.Container(contentWidth: 450.0) {
            Settings.Section(title: "") {
                Group {
                    PrefSectionText("Playback Settings")
                    
                    VStack(alignment: .leading) {
                        Picker("Audio Quality", selection: $audioQuality) {
                            Text("High 256kbps").tag(AudioQuality.High)
                            Text("Standard 64kbps").tag(AudioQuality.Standard)
                        }
                        .onChange(of: audioQuality) { audioQuality in
                            Debouncer.debounce {
                                Task {
                                    Defaults[.audioQuality] = audioQuality.rawValue
                                    await self.ciderPlayback.setAudioQuality(audioQuality)
                                }
                            }
                        }
                        
                        Text(audioQualityDescription)
                            .settingDescription()
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .enableInjection()
    }
}

struct AudioPreferencesPane_Previews: PreviewProvider {
    static var previews: some View {
        AudioPreferencesPane()
    }
}
