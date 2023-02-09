//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload
import SDWebImageSwiftUI
import Throttler

struct MediaPresentable: View {
    
    @ObservedObject private var iO = Inject.observer
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var navigationModal: NavigationModal
    
    var item: MediaDynamic
    var maxRelative: CGFloat
    
    @State private var isHovering = false
    @State private var isHoveringPlay = false
    
    @Namespace private var cardAnimation
    
    struct MediaPresentableData {
        let title: String
        let id: String
        let artwork: MusicArtwork
    }
    
    var displayData: MediaPresentableData {
        get {
            switch self.item {
                
            case .mediaItem(let musicItem):
                return MediaPresentableData(title: musicItem.title, id: musicItem.id, artwork: musicItem.artwork)
                
            case .mediaTrack(let mediaTrack):
                return MediaPresentableData(title: mediaTrack.title, id: mediaTrack.id, artwork: mediaTrack.artwork)
                
            }
        }
    }
    
    var innerBody: some View {
        VStack {
            WebImage(url: displayData.artwork.getUrl(width: 200, height: 200))
                .resizable()
                .placeholder {
                    ProgressView()
                }
                .scaledToFit()
                .frame(width: maxRelative * 0.15, height: maxRelative * 0.15)
                .cornerRadius(5)
                .matchedGeometryEffect(id: displayData.id, in: self.cardAnimation)
                .brightness(isHovering ? -0.1 : 0)
                .animation(.easeIn(duration: 0.15), value: isHovering)
                .overlay {
                    if isHovering {
                        HStack {
                            VStack {
                                let background = RoundedRectangle(cornerRadius: 20, style: .continuous)
                                
                                Spacer()
                                HStack {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(isHoveringPlay ? .pink : .primary)
                                    Text("Play")
                                }
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.ultraThinMaterial, in: background)
                                .contentShape(background)
                                .onHover { isHovering in
                                    self.isHoveringPlay = isHovering
                                }
                                .onTapGesture {
                                    Task {
                                        switch self.item {
                                        case .mediaItem(let mediaItem):
                                            await self.ciderPlayback.setQueue(musicItem: mediaItem)
                                            break
                                            
                                        case .mediaTrack(let mediaTrack):
                                            await self.ciderPlayback.setQueue(mediaTrack: mediaTrack)
                                            break
                                            
                                        }
                                        await self.ciderPlayback.play()
                                    }
                                }
                            }
                            .padding(.bottom, 10)
                            Spacer()
                        }
                        .padding(.leading, 10)
                        .transition(.opacity)
                    }
                }
                .onHover { isHovering in
                    self.isHovering = isHovering
                }
                .onTapGesture {
                    withAnimation(.interactiveSpring(response: 0.55, blendDuration: 100)) {
                        switch self.item {
                            
                        case .mediaItem(let musicItem):
                            self.navigationModal.appendViewStack(NavigationStack(stackType: .Media, isPresent: true, params: DetailedViewParams(mediaItem: musicItem, geometryMatching: self.cardAnimation, originalSize: CGSize(width: maxRelative * 0.15, height: maxRelative * 0.15))))
                            break
                            
                        default:
                            break
                            
                        }
                    }
                }
            
            Text("\(displayData.title)")
        }
        .frame(width: maxRelative * 0.15, height: maxRelative * 0.15)
        .fixedSize()
    }
    
    var body: some View {
        innerBody
            .enableInjection()
    }
}
