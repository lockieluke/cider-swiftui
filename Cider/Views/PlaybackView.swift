//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import SwiftUI
import Sliders
import Throttler
import Inject

struct PlaybackView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var navigationModal: NavigationModal
    
    private var repeatModeIcon: (icon: PlaybackButtonIcon, color: Color, nextTooltip: String) {
        switch ciderPlayback.playbackBehaviour.repeatMode {
        case .None:
            return (icon: .Repeat, color: .secondary, nextTooltip: "Repeat")
        case .All:
            return (icon: .Repeat, color: .pink, nextTooltip: "Repeat Track")
        case .One:
            return (icon: .RepeatOnce, color: .pink, nextTooltip: "Don't Repeat")
        }
    }
    
    var body: some View {
        ZStack {
            let playbackBehaviour = ciderPlayback.playbackBehaviour
            
            VStack {
                let nowPlayingState = ciderPlayback.nowPlayingState
                
                PlaybackBar()
                
                HStack {
                    PlaybackButton(icon: .Shuffle, tooltip: playbackBehaviour.shuffle ? "Don't Shuffle" : "Shuffle", highlighted: $ciderPlayback.playbackBehaviour.shuffle) {
                        Task {
                            await self.ciderPlayback.playbackEngine.setShuffleMode(!playbackBehaviour.shuffle)
                        }
                    }
                    PlaybackButton(icon: .Backward, tooltip: "Previous") {
                        Task {
                            await self.ciderPlayback.playbackEngine.skip(.Previous)
                        }
                    }
                    PlaybackButton(icon: nowPlayingState.isPlaying ? .Pause : .Play, tooltip: nowPlayingState.isPlaying ? "Pause" : "Play", size: 23) {
                        self.ciderPlayback.togglePlaybackSync()
                    }
                    PlaybackButton(icon: .Forward, tooltip: "Next") {
                        Task {
                            await self.ciderPlayback.playbackEngine.skip(.Next)
                        }
                    }
                    PlaybackButton(icon: repeatModeIcon.icon, color: repeatModeIcon.color, tooltip: repeatModeIcon.nextTooltip) {
                        Task {
                            await self.ciderPlayback.playbackEngine.setRepeatMode(playbackBehaviour.repeatMode.next())
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            
            HStack {
                PlaybackCardView()
                
                Spacer()
                
                let volume = Binding<Double>(get: { ciderPlayback.playbackBehaviour.volume }, set: { ciderPlayback.playbackBehaviour.volume = $0 })
                
                PatchedGeometryReader { geometry in
                    VolumeSlider(value: volume, inRange: 0.0...1.0, activeFillColor: .secondary, fillColor: .secondary.opacity(0.5), emptyColor: .secondary.opacity(0.3), height: 8) { _ in
                        Task {
                            await self.ciderPlayback.playbackEngine.setVolume(volume.wrappedValue)
                        }
                    }
                    .frame(width: (geometry.maxRelative * 0.3).clamped(to: 100...150))
                }
            }
            .padding(.horizontal, 20)
        }
        .enableInjection()
    }
}

enum PlaybackButtonIcon: String {
    
    case Play = "play.fill"
    case Pause = "pause.fill"
    case Backward = "backward.fill"
    case Forward = "forward.fill"
    case Repeat = "repeat"
    case RepeatOnce = "repeat.1"
    case Shuffle = "shuffle"
}

struct PlaybackButton: View {
    
    @ObservedObject private var iO = Inject.observer
    
    private var icon: PlaybackButtonIcon
    private var color: Color?
    private let tooltip: String?
    private var size = CGFloat(18)
    private var onClick: (() -> Void)? = nil
    
    @State private var isHovered = false
    @State private var bouncyFontSize: CGFloat = 18
    @Binding private var highlighted: Bool
    
    init(icon: PlaybackButtonIcon, color: Color? = .secondary, tooltip: String? = nil, highlighted: Binding<Bool> = .constant(false), size: CGFloat = 18, onClick: (() -> Void)? = nil) {
        self.icon = icon
        self.color = color
        self.tooltip = tooltip
        self._highlighted = highlighted
        self.size = size
        self.onClick = onClick
    }
    
    var body: some View {
        let view = Image(systemName: icon.rawValue)
            .animatableSystemFont(size: bouncyFontSize)
            .foregroundColor(color?.opacity(isHovered ? 0.5 : 1))
            .frame(width: 30, height: 30)
            .padding(.horizontal, 5)
            .contentShape(Rectangle())
            .background(RoundedRectangle(cornerRadius: 5).fill(.thinMaterial).isHidden(!highlighted))
            .gesture(DragGesture(minimumDistance: 0).onChanged({ _ in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 1)) {
                    self.bouncyFontSize = size - 5
                }
            }).onEnded({ _ in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 1)) {
                    self.bouncyFontSize = size
                    self.onClick?()
                }
            }))
            .onHover { isHovered in
                self.isHovered = isHovered
            }
            .onAppear {
                self.bouncyFontSize = size
            }
            .fixedSize()
            .enableInjection()
        
        if let tooltip = tooltip {
            view.background(Color.clear.tooltip(tooltip))
        } else {
            view
        }
    }
    
}

struct PlaybackView_Previews: PreviewProvider {
    static var previews: some View {
        PlaybackView()
            .environmentObject(AppWindowModal())
    }
}
