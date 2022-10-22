//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject

struct AMPresentable: View {
    
    @ObservedObject private var iO = Inject.observer
    
    public var recommendation: AMMediaItem
    private let PRESENTABLE_IMG_SIZE = CGSize(width: 200, height: 200)
    
    @State private var isHovering = false
    @State private var isHoveringPlay = false
    @State private var isClicked = false
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: recommendation.artwork.url.replacingOccurrences(of: "{w}", with: "200").replacingOccurrences(of: "{h}", with: "200"))) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: PRESENTABLE_IMG_SIZE.width, height: PRESENTABLE_IMG_SIZE.height)
                    .cornerRadius(5)
                    .brightness(isHovering ? (isClicked ? -0.15 : -0.1) : 0)
                    .animation(.easeIn(duration: 0.1), value: isHovering)
            } placeholder: {
                ProgressView()
            }
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
            .gesture(DragGesture(minimumDistance: 0).onChanged({ _ in
                self.isClicked = true
            }).onEnded({_ in
                self.isClicked = false
            }))
            Text("\(recommendation.title)")
        }
        .frame(width: PRESENTABLE_IMG_SIZE.width + 50, height: PRESENTABLE_IMG_SIZE.height + 50)
        .enableInjection()
    }
}
