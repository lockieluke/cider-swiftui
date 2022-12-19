//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import SwiftUISliders
import InjectHotReload

struct PlaybackBar: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    @State private var currentTimeValue: Double = 0.0
    
    var body: some View {
        HStack {
            let nowPlayingState = ciderPlayback.nowPlayingState
            Text("\(nowPlayingState.currentTime?.minuteSecond ?? "0:00")").isHidden(!nowPlayingState.hasItemToPlay)
            ValueSlider(value: nowPlayingState.hasItemToPlay ? $currentTimeValue : .constant(0), in: 0...Double(nowPlayingState.duration ?? 0), step: 1)
                .valueSliderStyle(HorizontalValueSliderStyle(
                    track: HorizontalRangeTrack(
                        view: Capsule().foregroundColor(.blue).background(.pink)
                    )
                    .frame(height: 5),
                    thumb: Circle().hideWithoutDestroying(!nowPlayingState.hasItemToPlay || !nowPlayingState.isReady),
                    thumbSize: CGSize(width: 8, height: 8),
                    thumbInteractiveSize: CGSize(width: 10, height: 10),
                    options: .interactiveTrack
                ))
                .frame(width: appWindowModal.windowSize.width / 3, height: 5)
            Text("\(nowPlayingState.duration?.minuteSecond ?? "0:00")").isHidden(!nowPlayingState.hasItemToPlay)
        }
        .padding(.vertical, 10)
        .onChange(of: self.ciderPlayback.nowPlayingState.currentTime) { newCurrentTime in
            self.currentTimeValue = Double(newCurrentTime ?? 0)
        }
        .enableInjection()
    }
}

struct PlaybackBar_Previews: PreviewProvider {
    static var previews: some View {
        PlaybackBar()
            .environmentObject(AppWindowModal())
    }
}
