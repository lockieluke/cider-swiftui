//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject

struct PlaybackView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var navigationModal: NavigationModal
    
    @State private var showCastMenu: Bool = false
    
    var repeatModeIcon: PlaybackButtonIcon {
        switch self.ciderPlayback.playbackBehaviour.repeatMode {
            
        case .None:
            return .Repeat
            
        case .One:
            return .RepeatOnce
            
        case .All:
            return .RepeatAll
            
        }
    }
    
    var nextRepeatModeTooltip: String {
        switch self.$ciderPlayback.playbackBehaviour.repeatMode.wrappedValue.next() {
            
        case .None:
            return "Don't Repeat"
            
        case .One:
            return "Repeat Once"
            
        case .All:
            return "Repeat All"
        }
    }
    
    var body: some View {
        ZStack {
            VisualEffectBackground()
                .overlay {
                    Rectangle().fill(Color("PrimaryColour")).opacity(0.5)
                }
            
            PlaybackCardView()
                .environmentObject(ciderPlayback)
                .environmentObject(navigationModal)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack {
                let nowPlayingState = self.ciderPlayback.nowPlayingState
                let playbackBehaviour = self.ciderPlayback.playbackBehaviour
                
                PlaybackBar()
                    .environmentObject(ciderPlayback)
                
                HStack {
                    PlaybackButton(icon: .Shuffle, tooltip: playbackBehaviour.shuffle ? "Don't Shuffle" : "Shuffle", highlighted: self.$ciderPlayback.playbackBehaviour.shuffle) {
                        Task {
                            await self.ciderPlayback.setShuffleMode(!playbackBehaviour.shuffle)
                        }
                    }
                    PlaybackButton(icon: .Backward, tooltip: "Previous") {
                        Task {
                            await self.ciderPlayback.skip(type: .Previous)
                        }
                    }
                    PlaybackButton(icon: nowPlayingState.isPlaying ? .Pause : .Play, tooltip: nowPlayingState.isPlaying ? "Pause" : "Play", size: 23) {
                        self.ciderPlayback.togglePlaybackSync()
                    }
                    PlaybackButton(icon: .Forward, tooltip: "Next") {
                        Task {
                            await self.ciderPlayback.skip(type: .Next)
                        }
                    }
                    PlaybackButton(icon: repeatModeIcon, tooltip: nextRepeatModeTooltip) {
                        Task {
                            await self.ciderPlayback.setRepeatMode(playbackBehaviour.repeatMode.next())
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            
            HStack {
                if ciderPlayback.nowPlayingState.playbackPipelineInitialised {
                    ActionButton(actionType: .AirPlay) {
                        Task {
                            guard let frame = self.appWindowModal.nsWindow?.frame else { return }
                            let supportsAirplay = await self.ciderPlayback.openAirPlayPicker(x: Int(frame.maxX - 125), y: Int(frame.minY + 70))
                            
                            if !supportsAirplay {
                                self.showCastMenu = true
                            }
                        }
                    }
                    .transition(.fade)
                }
                // TODO: Add alternate cast menu
                
                ActionButton(actionType: .Queue, enabled: $navigationModal.showQueue) {
                    withAnimation(.interactiveSpring()) {
                        if !self.navigationModal.showQueue {
                            self.navigationModal.showLyrics = false
                        }
                        self.navigationModal.showQueue.toggle()
                    }
                }
                if self.ciderPlayback.nowPlayingState.hasItemToPlay {
                    ActionButton(actionType: .Lyrics, enabled: $navigationModal.showLyrics) {
                        withAnimation(.interactiveSpring()) {
                            if !self.navigationModal.showLyrics {
                                self.navigationModal.showQueue = false
                            }
                            self.navigationModal.showLyrics.toggle()
                        }
                    }
                    .contextMenu([ContextMenuArg("Copy Lyrics XML", isDev: true)],  { id in
                        Task {
                            if id == "copy-lyrics-xml", let item = self.ciderPlayback.nowPlayingState.item, let lyricsXml = await self.mkModal.AM_API.fetchLyricsXml(item: item) {
                                NSPasteboard.general.declareTypes([.string], owner: nil)
                                NSPasteboard.general.setString(lyricsXml, forType: .string)
                            }
                        }
                    })
                    .transition(.fade)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 20)
        }
        .enableInjection()
    }
}

enum PlaybackButtonIcon : String {
    
    case Play = "play.fill";
    case Pause = "pause.fill";
    case Backward = "backward.fill";
    case Forward = "forward.fill";
    case Repeat = "repeat";
    case RepeatOnce = "repeat.1";
    case RepeatAll = "infinity"
    case Shuffle = "shuffle";
    
}

struct PlaybackButton: View {
    
    @ObservedObject private var iO = Inject.observer
    
    private var icon: PlaybackButtonIcon
    private let tooltip: String?
    private var size = CGFloat(18)
    private var onClick: (() -> Void)? = nil
    
    @State private var isHovered = false
    @State private var bouncyFontSize = CGFloat(18)
    @Binding private var highlighted: Bool
    
    init(icon: PlaybackButtonIcon, tooltip: String? = nil, highlighted: Binding<Bool> = .constant(false), size: CGFloat = 18, onClick: (() -> Void)? = nil) {
        self.icon = icon
        self.tooltip = tooltip
        self._highlighted = highlighted
        self.size = size
        self.onClick = onClick
    }
    
    var body: some View {
        let view = Image(systemName: icon.rawValue)
            .animatableSystemFont(size: bouncyFontSize)
            .foregroundColor(.secondary.opacity(isHovered ? 0.5 : 1))
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
