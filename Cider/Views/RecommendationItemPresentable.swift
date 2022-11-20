//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload
import SDWebImageSwiftUI

struct RecommendationItemPresentable: View {
    
    @ObservedObject private var iO = Inject.observer
    @ObservedObject private var appWindowModal = AppWindowModal.shared
    
    public var recommendation: MusicItem
    
    private let sizeMultipler: CGFloat = 0.3
    private let minSize: CGFloat = 160
    private let maxSize: CGFloat = 190
    @State private var relativeSize: CGFloat = 0
    
    @State private var isHovering = false
    @State private var isHoveringPlay = false
    @State private var isClicked = false
    
    func calculateRelativeSize(baseHeight: CGFloat) -> CGFloat {
        let newSize = baseHeight * sizeMultipler
        return newSize < minSize ? minSize : (newSize > maxSize ? maxSize : newSize)
    }
    
    var body: some View {
        VStack {
            WebImage(url: URL(string: recommendation.artwork.url.replacingOccurrences(of: "{w}", with: "200").replacingOccurrences(of: "{h}", with: "200")))
                .resizable()
                .placeholder {
                    ProgressView()
                }
                .scaledToFit()
                .frame(width: relativeSize, height: relativeSize)
                .cornerRadius(5)
                .brightness(isHovering ? (isClicked ? -0.15 : -0.1) : 0)
                .animation(.easeIn(duration: 0.1), value: isHovering)
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
                                        switch recommendation.type {
                                            
                                        case .Album:
                                            await CiderPlayback.shared.setQueue(album: recommendation.id)
                                            break
                                            
                                        case .Playlist:
                                            await CiderPlayback.shared.setQueue(playlist: recommendation.id)
                                            break
                                            
                                        default:
                                            break
                                            
                                        }
                                        
                                        await CiderPlayback.shared.play()
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
                    withAnimation(.easeIn(duration: 0.15)) {
                        self.isHovering = isHovering
                    }
                }
                .onTapGesture {
                    print("Clicked \(recommendation.id)")
                }
                .gesture(DragGesture(minimumDistance: 0).onChanged({ _ in
                    self.isClicked = true
                }).onEnded({_ in
                    self.isClicked = false
                }))
            Text("\(recommendation.title)")
        }
        .frame(width: relativeSize, height: relativeSize)
        .onChange(of: appWindowModal.windowSize) { newWindowSize in
            self.relativeSize = self.calculateRelativeSize(baseHeight: newWindowSize.height)
        }
        .onAppear {
            self.relativeSize = self.calculateRelativeSize(baseHeight: appWindowModal.windowSize.height)
        }
        .padding()
        .enableInjection()
    }
}
