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
    
    private let sizeMultipler: CGFloat = 0.3
    private let minSize: CGFloat = 160
    private let maxSize: CGFloat = 190
    
    @State private var relativeSize = CGSize()
    @State private var absXY = CGPoint()
    @State private var isHovering = false
    @State private var isHoveringPlay = false
    
    @Namespace private var cardAnimation
    
    func calculateRelativeSize(baseHeight: CGFloat) -> CGFloat {
        let newSize = baseHeight * sizeMultipler
        return newSize < minSize ? minSize : (newSize > maxSize ? maxSize : newSize)
    }
    
    func getAppropriateSize(sizeMultiplier: CGFloat = 1) -> CGSize {
        let size = self.calculateRelativeSize(baseHeight: appWindowModal.windowSize.height) * sizeMultiplier
        return CGSize(width: size, height: size)
    }
    
    func resizeCover(sizeMultiplier: CGFloat = 1) {
        self.relativeSize = self.getAppropriateSize(sizeMultiplier: sizeMultiplier)
    }
    
    var body: some View {
        VStack {
            WebImage(url: recommendation.artwork.getUrl(width: 200, height: 200))
                .resizable()
                .placeholder {
                    ProgressView()
                }
                .scaledToFit()
                .frame(width: relativeSize.width, height: relativeSize.height)
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
                        self.navigationModal.appendViewStack(NavigationStack(stackType: .Media, isPresent: true, params: DetailedViewParams(mediaItem: self.recommendation, geometryMatching: self.cardAnimation, originalSize: self.relativeSize)))
                    }
                }
            
            Text("\(recommendation.title)")
        }
        .frame(width: relativeSize.width, height: relativeSize.height)
        .background(GeometryReader { geometry in
            Color.clear.onAppear {
                self.absXY = geometry.frame(in: .global).origin
            }
        })
        .onChange(of: appWindowModal.windowSize) { newWindowSize in
            if self.navigationModal.currentRootStack == .Home {
                self.resizeCover()
            }
        }
        .onAppear {
            self.resizeCover()
        }
        .padding()
        .enableInjection()
    }
}
