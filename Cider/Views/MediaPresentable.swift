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
    private let coverKind: String
    private let isHostOrArtist: Bool
    
    private let animationNamespace: Namespace.ID?
    private let animationId = UUID().uuidString
    
    private var id, title: String!
    private var artwork: MediaArtwork!
    
    @State private var isHovering = false
    @State private var isHoveringPlay = false
    
    init(item: MediaDynamic,
         maxRelative: CGFloat,
         coverKind: String = "bb",
         isHostOrArtist: Bool = false,
         animationNamespace: Namespace.ID? = nil
    ) {
        self.id = item.id
        self.title = item.title
        self.artwork = item.artwork
        
        self.item = item
        self.maxRelative = maxRelative
        self.isHostOrArtist = isHostOrArtist
        self.coverKind = coverKind
        
        self.animationNamespace = animationNamespace
    }
    
    var innerBody: some View {
        VStack {
            ZStack {
                WebImage(url: artwork.getUrl(width: 200, height: 200, kind: coverKind), options: [.retryFailed])
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: maxRelative * 0.15, height: maxRelative * 0.15, alignment: .center)
                    .fixedSize()
                    .cornerRadius(isHostOrArtist ? .infinity : 5)
                    .brightness(isHovering ? -0.1 : 0)
                    .animation(.easeIn(duration: 0.15), value: isHovering)
                    .allowsHitTesting(false)
                    .onHover { isHovering in
                        self.isHovering = isHovering
                    }
                    .onTapGesture {
                        withAnimation(.spring) {
                            if case let .mediaItem(mediaItem) = item {
                                self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .detailedViewParams(DetailedViewParams(item: .mediaItem(mediaItem), geometryMatching: self.animationNamespace.isNil ? nil : self.animationNamespace!, animationId: self.animationId, originalSize: CGSize(width: maxRelative * 0.15, height: maxRelative * 0.15), coverKind: self.coverKind))))
                            } else if case let .mediaPlaylist(mediaPlaylist) = item {
                                self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .detailedViewParams(DetailedViewParams(item: .mediaPlaylist(mediaPlaylist), geometryMatching: self.animationNamespace.isNil ? nil : self.animationNamespace!, animationId: self.animationId, originalSize: CGSize(width: maxRelative * 0.15, height: maxRelative * 0.15), coverKind: self.coverKind))))
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
                                    await self.ciderPlayback.playbackEngine.setQueue(item: self.item)
                                    await self.ciderPlayback.playbackEngine.play(shuffle: false)
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
            .if(!animationNamespace.isNil) { view in
                view
                    .onTapGesture {
                        withAnimation(.spring) {
                            if case let .mediaItem(mediaItem) = item {
                                self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .detailedViewParams(DetailedViewParams(item: .mediaItem(mediaItem), geometryMatching: self.animationNamespace.isNil ? nil : self.animationNamespace!, animationId: self.animationId, originalSize: CGSize(width: maxRelative * 0.15, height: maxRelative * 0.15), coverKind: self.coverKind))))
                            } else if case let .mediaPlaylist(mediaPlaylist) = item {
                                self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .detailedViewParams(DetailedViewParams(item: .mediaPlaylist(mediaPlaylist), geometryMatching: self.animationNamespace.isNil ? nil : self.animationNamespace!, animationId: self.animationId, originalSize: CGSize(width: maxRelative * 0.15, height: maxRelative * 0.15), coverKind: self.coverKind))))
                            }
                        }
                    }
                    .matchedGeometryEffect(id: "MediaPresentable-\(animationId)", in: animationNamespace!, properties: .frame, isSource: true)
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
