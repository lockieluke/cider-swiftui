//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload
import SDWebImageSwiftUI
import UIImageColors

struct DetailedView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var mkModal: MKModal
    
    @State private var size: CGSize = .zero
    @State private var animationFinished = false
    @State private var descriptionsShouldLoadIn = false
    @State private var bgGlowGradientColours = Gradient(colors: [])
    // copy of the recommendation, this one isn't read only
    @State private var reflectedMusicItem = MusicItem(data: [])
    
    func calculateRelativeSize() {
        self.size = CGSize(width: appWindowModal.windowSize.width * 0.03, height: appWindowModal.windowSize.height * 0.03)
    }
    
    var playButton: some View {
        Button {
            
        } label: {
            Image(systemName: "play.fill")
            Text("Play")
        }
        .buttonStyle(.borderless)
        .frame(width: 65, height: 25)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.pink))
        .modifier(SimpleHoverModifier())
    }
    
    var body: some View {
        if let mediaItem = navigationModal.detailedViewParams?.mediaItem,
           let animationNamespace = navigationModal.detailedViewParams?.geometryMatching,
           let originalSize = navigationModal.detailedViewParams?.originalSize
        {
            ResponsiveLayoutReader { windowProps in
                HStack(spacing: 0) {
                    VStack {
                        let size = CGSize(width: windowProps.size.width * 0.33, height: windowProps.size.height * 0.33)
                        
                        // there's a slight delay before copying the state to reflectedMediaItem, use original mediaItem data to fetch the image
                        WebImage(url: mediaItem.artwork.getUrl(width: 600, height: 600))
                            .onSuccess { image, data, cacheType in
                                image.getColors(quality: .highest) { colours in
                                    guard let colours = colours else { return }
                                    self.bgGlowGradientColours = Gradient(colors: [Color(nsColor: colours.primary), Color(nsColor: colours.secondary), Color(nsColor: colours.detail), Color(nsColor: colours.background)])
                                }
                            }
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(5)
                            .frame(width: size.width, height: size.height)
                            .background(
                                Rectangle()
                                    .background(Color(nsColor: reflectedMusicItem.artwork.bgColour))
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(5)
                                    .multicolourGlow()
                            )
                            .aspectRatio(1, contentMode: .fill)
                            .matchedGeometryEffect(id: mediaItem.id, in: animationNamespace)
                            .onAppear {
                                self.size = originalSize
                                withAnimation(.interactiveSpring()) {
                                    self.size = CGSize(width: 250, height: 250)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) {
                                        withAnimation(.spring()) {
                                            self.descriptionsShouldLoadIn = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) {
                                            withAnimation(.spring()) {
                                                self.animationFinished = true
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 10)
                        
                        if descriptionsShouldLoadIn {
                            Group {
                                HStack {
                                    Text("\(reflectedMusicItem.title)")
                                        .font(.system(size: 18, weight: .bold))
                                    if reflectedMusicItem.playlistType == .PersonalMix {
                                        Image(systemName: "person.crop.circle").foregroundColor(Color(nsColor: reflectedMusicItem.artwork.bgColour))
                                            .font(.system(size: 18))
                                            .toolTip("Playlist curated by Apple Music")
                                            .modifier(SimpleHoverModifier())
                                    }
                                }
                                Text("\(reflectedMusicItem.curatorName)")
                                    .foregroundColor(.gray)
                                
                                if let description = reflectedMusicItem.description {
                                    Text("\(description)")
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 2)
                                        .frame(maxWidth: 150)
                                }
                                
                                playButton
                            }
                            .isHidden(!animationFinished)
                            .transition(.move(edge: .bottom).animation(.interactiveSpring()))
                        }
                    }
                    
                    Spacer()
                    
                    ScrollView(.vertical) {
                        LazyVStack {
                            ForEach(reflectedMusicItem.tracks, id: \.id) { track in
                                MediaTrackRepresentable(mediaItem: track)
                            }
                        }
                        .padding(.vertical)
                    }
                    .transparentScrollbars()
                    .frame(width: .infinity)
                    .task {
                        self.reflectedMusicItem.tracks = try! await self.mkModal.AM_API.fetchTracks(id: reflectedMusicItem.id, type: reflectedMusicItem.type)
                    }
                    .onAppear {
                        self.reflectedMusicItem = mediaItem
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.leading, 30)
            }
            .environmentObject(appWindowModal)
            .onDisappear {
                self.reflectedMusicItem.tracks = []
                self.reflectedMusicItem = MusicItem(data: [])
            }
            .enableInjection()
        }
    }
}

struct DetailedView_Previews: PreviewProvider {
    static var previews: some View {
        DetailedView()
    }
}
