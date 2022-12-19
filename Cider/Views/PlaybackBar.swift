//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload

struct PlaybackBar: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    var body: some View {
        HStack {
            let nowPlayingState = ciderPlayback.nowPlayingState
            Text("\(nowPlayingState.currentTime?.minuteSecond ?? "0:00")").isHidden(!nowPlayingState.hasItemToPlay)
            ZStack {
                
                HStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(nowPlayingState.isReady ? .red : .blue)
                        .frame(width: appWindowModal.windowSize.width / 3, height: 5)
                }
            }
            Text("\(nowPlayingState.duration?.minuteSecond ?? "0:00")").isHidden(!nowPlayingState.hasItemToPlay)
        }
        .padding(.vertical, 10)
        .enableInjection()
    }
}

struct PlaybackBar_Previews: PreviewProvider {
    static var previews: some View {
        PlaybackBar()
            .environmentObject(AppWindowModal())
    }
}
