//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload

struct PlaybackView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    @State private var geometrySize = CGSize()
    
    var body: some View {
        ZStack {
            VisualEffectBackground()
                .frame(width: appWindowModal.windowSize.width, height: geometrySize.height)
                .overlay {
                    Rectangle().fill(Color("PrimaryColour")).opacity(0.5)
                }
            
            PlaybackCardView()
                .environmentObject(ciderPlayback)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack {
                let nowPlayingState = self.ciderPlayback.nowPlayingState
                
                PlaybackBar()
                    .environmentObject(ciderPlayback)
                
                HStack {
                    PlaybackButton(icon: .Shuffle)
                    PlaybackButton(icon: .Backward)
                    PlaybackButton(icon: nowPlayingState.isPlaying ? .Pause : .Play, size: 23) {
                        self.ciderPlayback.togglePlaybackSync()
                    }
                    PlaybackButton(icon: .Forward)
                    PlaybackButton(icon: .Repeat)
                }
            }
            
            HStack {
                ActionButton(actionType: .AirPlay)
                ActionButton(actionType: .Queue)
                ActionButton(actionType: .More)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 20)
        }
        .overlay {
            GeometryReader { geometry in
                EmptyView()
                    .onChange(of: geometry.size) { newSize in
                        self.geometrySize = newSize
                    }
                    .onAppear {
                        self.geometrySize = geometry.size
                    }
            }
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .enableInjection()
    }
}

enum PlaybackButtonIcon : String {
    
    case Play = "play.fill";
    case Pause = "pause.fill";
    case Backward = "backward.fill";
    case Forward = "forward.fill";
    case Repeat = "repeat";
    case Shuffle = "shuffle";
    
}

struct PlaybackButton: View {
    
    @ObservedObject private var iO = Inject.observer
    
    private var icon: PlaybackButtonIcon
    private var size = CGFloat(18)
    private var onClick: (() -> Void)? = nil
    
    init(icon: PlaybackButtonIcon, size: CGFloat = 18, onClick: (() -> Void)? = nil) {
        self.icon = icon
        self.size = size
        self.onClick = onClick
    }
    
    @State private var isHovered = false
    @State private var bouncyFontSize = CGFloat(18)
    
    var body: some View {
        Image(systemName: icon.rawValue)
            .animatableSystemFont(size: bouncyFontSize)
            .foregroundColor(.secondary.opacity(isHovered ? 0.5 : 1))
            .frame(width: 30, height: 30)
            .padding(.horizontal, 5)
            .contentShape(Rectangle())
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
    }
    
}

struct PlaybackView_Previews: PreviewProvider {
    static var previews: some View {
        PlaybackView()
            .environmentObject(AppWindowModal())
    }
}
