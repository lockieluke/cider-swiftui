//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload
import SDWebImageSwiftUI
import Throttler

struct RecommendationItemPresentable: View {
    
    @ObservedObject private var iO = Inject.observer
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var navigationModal: NavigationModal
    
    var recommendation: MusicItem
    var maxRelative: CGFloat
    
    @State private var isHovering = false
    @State private var isHoveringPlay = false
    
    @Namespace private var cardAnimation
    
    var innerBody: some View {
        VStack {
            WebImage(url: recommendation.artwork.getUrl(width: 200, height: 200))
                .resizable()
                .placeholder {
                    ProgressView()
                }
                .scaledToFit()
                .frame(width: maxRelative * 0.15, height: maxRelative * 0.15)
                .cornerRadius(5)
                .matchedGeometryEffect(id: recommendation.id, in: self.cardAnimation)
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
                                        await self.ciderPlayback.setQueue(musicItem: self.recommendation)
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
                        self.navigationModal.appendViewStack(NavigationStack(stackType: .Media, isPresent: true, params: DetailedViewParams(mediaItem: self.recommendation, geometryMatching: self.cardAnimation, originalSize: .zero)))
                    }
                }
            
            Text("\(recommendation.title)")
        }
        .frame(width: maxRelative * 0.15, height: maxRelative * 0.15)
        .padding()
        .fixedSize()
    }
    
    var body: some View {
        innerBody
            .enableInjection()
    }
}
