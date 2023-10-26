//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Sliders
import Inject
import Throttler

struct PlaybackBar: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    @State private var currentTimeValue: Double = 0.0
    @State private var playbackBarWidth: CGFloat = .zero
    @State private var playbackGradientRadius = false
    @State private var shouldShowThumb = false
    @State private var isEditingTrack = false
    
    var body: some View {
        PatchedGeometryReader { geometry in
            HStack {
                let nowPlayingState = ciderPlayback.nowPlayingState
                let overlayBarWidth = currentTimeValue / nowPlayingState.duration
                let playbackBarWidth = currentTimeValue == 0 ? 0 : self.playbackBarWidth * overlayBarWidth.f + 1
                Text("\(isEditingTrack ? currentTimeValue.minuteSecond : (nowPlayingState.currentTime?.minuteSecond ?? "0:00"))").isHidden(!nowPlayingState.hasItemToPlay)
                
                ValueSlider(value: nowPlayingState.hasItemToPlay ? $currentTimeValue : .constant(0), in: 0...nowPlayingState.duration, step: 1, onEditingChanged: { isEditing in
                    if isEditing != self.isEditingTrack {
                        Debouncer.debounce(delay: .milliseconds(100), shouldRunImmediately: false) {
                            DispatchQueue.main.async {
                                Task {
                                    await self.ciderPlayback.seekToTime(seconds: Int(currentTimeValue))
                                    self.isEditingTrack = isEditing
                                }
                            }
                        }
                    }
                })
                .valueSliderStyle(HorizontalValueSliderStyle(
                    track: HorizontalRangeTrack(
                        view: ZStack(alignment: .leading) {
                            Capsule()
                                .foregroundColor(nowPlayingState.isReady ? Color("PrimaryColour") : .clear)
                                .background(nowPlayingState.isReady ? Color.clear.erasedToAnyView() : LinearGradient(colors: [.pink, .red], startPoint: playbackGradientRadius ? .leading : .trailing, endPoint: playbackGradientRadius ? .trailing : .leading)
                                    .onAppear {
                                        withAnimation(.linear.repeatForever(autoreverses: false)) {
                                            self.playbackGradientRadius.toggle()
                                        }
                                    }
                                    .erasedToAnyView())
                                .overlay {
                                    GeometryReader { geometry in
                                        Color.clear
                                            .onChange(of: geometry.size) { newSize in
                                                Debouncer.debounce {
                                                    self.playbackBarWidth = newSize.width
                                                }
                                            }
                                            .onAppear {
                                                self.playbackBarWidth = geometry.size.width
                                            }
                                    }
                                }
                            
                            Capsule().foregroundColor(.pink)
                                .frame(width: playbackBarWidth)
                        }
                    )
                    .onHover { isHovering in
                        self.shouldShowThumb = isHovering
                    }
                        .background {
                            Rectangle()
                                .fill(.clear)
                                .frame(width: playbackBarWidth, height: 30)
                                .onHover { isHovering in
                                    self.shouldShowThumb = isHovering
                                }
                                .allowsHitTesting(false)
                        }
                        .frame(height: 5),
                    thumb: Circle()
                        .onHover { isHovering in
                            self.shouldShowThumb = isHovering
                        }
                        .hideWithoutDestroying(!nowPlayingState.hasItemToPlay || !shouldShowThumb)
                    ,
                    thumbSize: CGSize(width: 8, height: 8),
                    thumbInteractiveSize: CGSize(width: 10, height: 10),
                    options: .interactiveTrack
                ))
                .frame(width: geometry.minRelative * 20, height: 5)
                
                Text("\(ciderPlayback.nowPlayingState.duration.minuteSecond)").isHidden(!nowPlayingState.hasItemToPlay)
            }
            .onChange(of: self.ciderPlayback.nowPlayingState.currentTime) { newCurrentTime in
                if newCurrentTime == self.ciderPlayback.nowPlayingState.duration {
                    self.ciderPlayback.nowPlayingState.reset()
                } else if !isEditingTrack {
                    self.currentTimeValue = Double(newCurrentTime ?? 0)
                }
            }
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
