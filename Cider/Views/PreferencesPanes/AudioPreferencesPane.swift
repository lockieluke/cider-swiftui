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
    
    @Default(.audioQuality) private var audioQuality
    @Default(.playbackBackend) private var playbackBackend
    
    private var audioQualityDescription: String {
        get {
            switch self.audioQuality {
                
            case .Standard:
                return "Standard Quality contains less detail of the audio but can help save network bandwidth"
                
                
            case .High:
                return "High Quality contains more detail of the audio but consumes more network bandwidth"
                
            case .Lossless:
                return "Lossless contains every bit of the audio but consumes a lot more network bandwidth, this functionality is still in beta and only works on macOS 14.0 and newer"
                
            }
        }
    }
    
    private var playbackBackendDescription: String {
        get {
            switch self.playbackBackend {
                
            case .MKJS:
                return "MusicKit JS is the default, most reliable playback engine for \(Bundle.main.displayName)"
                
            }
        }
    }
    
    var body: some View {
        Settings.Container(contentWidth: 450.0) {
            Settings.Section(title: "") {
                Group {
                    PrefSectionText("Playback Settings")
                    
                    VStack(alignment: .leading) {
                        Picker("Playback Engine", selection: $playbackBackend) {
                            Text("MusicKit JS").tag(PlaybackEngineType.MKJS)
                        }
                        .onChange(of: playbackBackend) { playbackBackend in
                            Defaults[.playbackBackend] = playbackBackend
                        }
                        Text("\(playbackBackendDescription).  Changes require restart")
                            .settingDescription()
                        
                        Spacer()
                            .frame(height: 20)
                        
                        Picker("Audio Quality", selection: $audioQuality) {
                            Text("High 256kbps").tag(AudioQuality.High)
                            Text("Standard 64kbps").tag(AudioQuality.Standard)
                            Text("Lossless (Beta)").tag(AudioQuality.Lossless)
                        }
                        .onChange(of: audioQuality) { audioQuality in
                            Debouncer.debounce {
                                Task {
                                    Defaults[.audioQuality] = audioQuality
                                    await self.ciderPlayback.playbackEngine.setAudioQuality(audioQuality)
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
