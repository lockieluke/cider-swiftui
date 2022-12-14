//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Preferences
import InjectHotReload

struct AudioPreferencesPane: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var prefModal: PrefModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    var audioQualityDescription: String {
        get {
            switch self.prefModal.prefs.audioQuality {
                
            case .Standard:
                return "Standard Quality contains less detail of the audio but can help save network bandwidth"
                
                
            case .High:
                return "High Quality contains more detail of the audio but consumes more network bandwidth"
                
            }
        }
    }
    
    var body: some View {
        Preferences.Container(contentWidth: 450.0) {
            Preferences.Section(title: "") {
                Group {
                    PrefSectionText("Playback Settings")
                    
                    VStack(alignment: .leading) {
                        Picker("Audio Quality", selection: $prefModal.prefs.audioQuality) {
                            Text("High 256kbps").tag(AudioQuality.High)
                            Text("Standard 64kbps").tag(AudioQuality.Standard)
                        }
                        .onChange(of: prefModal.prefs.audioQuality) { audioQuality in
                            Task {
                                await self.ciderPlayback.setAudioQuality(audioQuality)
                            }
                        }
                        
                        Text(audioQualityDescription)
                            .preferenceDescription()
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
