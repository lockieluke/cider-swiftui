//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject
import SDWebImageSwiftUI
import Throttler

struct MediaPresentable: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var navigationModal: NavigationModal
    
    private let item: MediaDynamic
    private let maxRelative: CGFloat
    private let geometryMatched: Bool
    private let coverKind: String
    
    private var id, title: String!
    private var artwork: MediaArtwork!
    
    @State private var isHovering = false
    @State private var isHoveringPlay = false
    
    @Namespace private var cardAnimation
    
    init(item: MediaDynamic, maxRelative: CGFloat, coverKind: String = "bb", geometryMatched: Bool = false) {
        if case .mediaItem(let mediaItem) = item {
            self.id = mediaItem.id
            self.title = mediaItem.title
            self.artwork = mediaItem.artwork
        } else if case .mediaPlaylist(let mediaPlaylist) = item {
            self.id = mediaPlaylist.id
            self.title = mediaPlaylist.title
            self.artwork = mediaPlaylist.artwork
        } else if case .mediaTrack(let mediaTrack) = item {
            self.id = mediaTrack.id
            self.title = mediaTrack.title
            self.artwork = mediaTrack.artwork
        }
        
        self.item = item
        self.maxRelative = maxRelative
        self.geometryMatched = geometryMatched
        self.coverKind = coverKind
    }
    
    var innerBody: some View {
        VStack {
            let artworkView = ZStack {
                WebImage(url: artwork.getUrl(width: 200, height: 200, kind: coverKind))
                    .resizable()
                    .indicator(.progress)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: maxRelative * 0.15, height: maxRelative * 0.15, alignment: .center)
                    .clipped()
                    .cornerRadius(5)
                    .brightness(isHovering ? -0.1 : 0)
                    .animation(.easeIn(duration: 0.15), value: isHovering)
                    .allowsHitTesting(false)
                    .onHover { isHovering in
                        self.isHovering = isHovering
                    }
                    .onTapGesture {
                        withAnimation(.interactiveSpring(response: 0.55, blendDuration: 100)) {
                            if case let .mediaItem(mediaItem) = item {
                                self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .detailedViewParams(DetailedViewParams(item: .mediaItem(mediaItem), geometryMatching: self.geometryMatched ? self.cardAnimation : nil, originalSize: CGSize(width: maxRelative * 0.15, height: maxRelative * 0.15), coverKind: self.coverKind))))
                            } else if case let .mediaPlaylist(mediaPlaylist) = item {
                                self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .detailedViewParams(DetailedViewParams(item: .mediaPlaylist(mediaPlaylist), geometryMatching: self.geometryMatched ? self.cardAnimation : nil, originalSize: CGSize(width: maxRelative * 0.15, height: maxRelative * 0.15), coverKind: self.coverKind))))
                            }
                        }
                    }
                    .modifier(CatalogActions(item: item))
                
                if isHovering {
                    HStack {
                        VStack {
                            let background = RoundedRectangle(cornerRadius: 20, style: .continuous)
                            
                            Spacer()
                            HStack {
                                Image(systemSymbol: .playFill)
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
                            .onHover { isHoveringPlay in
                                self.isHoveringPlay = isHoveringPlay
                            }
                            .onTapGesture {
                                Task {
                                    await self.ciderPlayback.setQueue(item: self.item)
                                    await self.ciderPlayback.play()
                                }
                            }
                        }
                        .padding(.bottom, 10)
                        Spacer()
                    }
                    .frame(width: maxRelative * 0.15, height: maxRelative * 0.15, alignment: .center)
                    .padding(.leading, 10)
                    .transition(.opacity)
                }
            }
            
            if geometryMatched, let id = self.id {
                artworkView
                    .matchedGeometryEffect(id: id, in: cardAnimation)
            } else {
                artworkView
            }
            
            Text("\(title)")
        }
        .frame(width: maxRelative * 0.15, height: maxRelative * 0.15, alignment: .center)
        .fixedSize()
    }
    
    var body: some View {
        innerBody
            .enableInjection()
    }
}
