//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Sliders
import Inject

struct PlaybackBar: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    @State private var currentTimeValue: Double = 0.0
    @State private var playbackBarWidth: CGFloat = .zero
    @State private var playbackGradientRadius = false
    @State private var shouldShowThumb = false
    @State private var isEditingTrack = false
    @State private var duration: TimeInterval = 0
    
    var body: some View {
        PatchedGeometryReader { geometry in
            if appWindowModal.isVisibleInViewport {
                HStack {
                    let nowPlayingState = ciderPlayback.nowPlayingState
                    let overlayBarWidth = currentTimeValue / duration
                    let _playbackBarWidth = currentTimeValue == 0 ? 0 : self.playbackBarWidth * overlayBarWidth.f + 1
                    Text("\(isEditingTrack ? currentTimeValue.minuteSecond : (nowPlayingState.currentTime?.minuteSecond ?? "0:00"))").isHidden(!nowPlayingState.hasItemToPlay)
                    
                    ValueSlider(value: nowPlayingState.hasItemToPlay ? $currentTimeValue : .constant(0), in: 0...duration.clamped(to: 1...TimeInterval(Int.max)), step: 1, onEditingChanged: { isEditing in
                        if isEditing != self.isEditingTrack {
                            DispatchQueue.main.async {
                                Task {
                                    await self.ciderPlayback.playbackEngine.seekToTime(seconds: Int(currentTimeValue))
                                    self.isEditingTrack = isEditing
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
                                                    self.playbackBarWidth = newSize.width
                                                }
                                                .onAppear {
                                                    self.playbackBarWidth = geometry.size.width
                                                }
                                        }
                                    }
                                    .drawingGroup()
                                
                                Capsule().foregroundColor(.pink)
                                    .frame(width: abs(_playbackBarWidth))
                                    .drawingGroup()
                            }
                        )
                        .onHover { isHovering in
                            self.shouldShowThumb = isHovering
                        }
                            .background {
                                Rectangle()
                                    .fill(.clear)
                                    .frame(width: abs(_playbackBarWidth), height: 30)
                                    .onHover { isHovering in
                                        self.shouldShowThumb = isHovering
                                    }
                                    .allowsHitTesting(false)
                                    .drawingGroup()
                            }
                            .frame(height: 5),
                        thumb: Circle()
                            .onHover { isHovering in
                                self.shouldShowThumb = isHovering
                            }
                            .drawingGroup()
                            .hideWithoutDestroying(!nowPlayingState.hasItemToPlay || !shouldShowThumb)
                        ,
                        thumbSize: CGSize(width: 8, height: 8),
                        thumbInteractiveSize: CGSize(width: 10, height: 10),
                        options: .interactiveTrack
                    ))
                    .frame(width: geometry.minRelative * 20, height: 5)
                    
                    Text("\(duration.minuteSecond)").isHidden(!nowPlayingState.hasItemToPlay)
                }
                .drawingGroup()
                .onChange(of: self.ciderPlayback.nowPlayingState.currentTime) { newCurrentTime in
                    if newCurrentTime == self.duration {
                        self.ciderPlayback.nowPlayingState.reset()
                    } else if !isEditingTrack {
                        self.currentTimeValue = Double(newCurrentTime ?? 0)
                    }
                }
            }
        }
        .onChange(of: self.ciderPlayback.nowPlayingState.duration) { newDuration in
            if newDuration != .zero && newDuration > 0 && self.ciderPlayback.nowPlayingState.playbackPipelineInitialised {
                self.duration = newDuration
            } else if self.ciderPlayback.nowPlayingState.item.isNil && !self.ciderPlayback.nowPlayingState.isPlaying {
                self.duration = 0
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
