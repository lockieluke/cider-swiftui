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
        ZStack {
            let nowPlayingState = ciderPlayback.nowPlayingState
            
            RoundedRectangle(cornerRadius: 5)
                .fill(nowPlayingState.isReady ? .red : .blue)
                .frame(width: appWindowModal.windowSize.width / 3, height: 5)
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
