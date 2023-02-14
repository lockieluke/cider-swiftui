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
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    var detailedViewParams: DetailedViewParams
    
    @State private var size: CGSize = .zero
    @State private var animationFinished = false
    @State private var descriptionsShouldLoadIn = false
    @State private var tracksShouldLoadIn = false
    @State private var bgGlowGradientColours = Gradient(colors: [])
    // copy of the recommendation, this one isn't read only
    @State private var reflectedMusicItem: MediaItem? = nil
    
    init(detailedViewParams: DetailedViewParams) {
        self.detailedViewParams = detailedViewParams
    }
    
    var addToLibrary: some View {
        Button {
            
        } label: {
            HStack {
                Image(systemName: "plus")
                Text("Add to Library")
            }
            .padding(.horizontal)
        }
        .buttonStyle(.borderless)
        .frame(height: 25)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color("SecondaryColour").opacity(0.5)))
        .modifier(SimpleHoverModifier())
    }
    
    func playSync(mediaItem: MediaItem, shuffle: Bool = false) {
        Task {
            if let reflectedMusicItem = self.reflectedMusicItem {
                await self.ciderPlayback.setQueue(musicItem: reflectedMusicItem)
                await self.ciderPlayback.clearAndPlay(shuffle: shuffle, musicItem: reflectedMusicItem)
            }
        }
    }
    
    var body: some View {
        let mediaItem = self.detailedViewParams.mediaItem
        let originalSize = self.detailedViewParams.originalSize
        
        PatchedGeometryReader { geometry in
            HStack(spacing: 0) {
                VStack {
                    let sqaureSize = geometry.minRelative * 0.4
                    
                    // there's a slight delay before copying the state to reflectedMediaItem, use original mediaItem data to fetch the image
                    let artwork = WebImage(url: mediaItem.artwork.getUrl(width: 600, height: 600))
                        .onSuccess { image, data, cacheType in
                            image.getColors(quality: .highest) { colours in
                                guard let colours = colours else { return }
                                self.bgGlowGradientColours = Gradient(colors: [Color(nsColor: colours.primary), Color(nsColor: colours.secondary), Color(nsColor: colours.detail), Color(nsColor: colours.background)])
                            }
                        }
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(5)
                        .frame(width: sqaureSize)
                        .background(
                            Rectangle()
                                .background(Color(nsColor: reflectedMusicItem?.artwork.bgColour ?? .gray))
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(5)
                                .multicolourGlow()
                        )
                        .aspectRatio(1, contentMode: .fill)
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
                        .padding(.vertical, 5)
                    
                    if let animationNamespace = self.detailedViewParams.geometryMatching {
                        artwork.matchedGeometryEffect(id: mediaItem.id, in: animationNamespace)
                    } else {
                        artwork
                    }
                    
                    if descriptionsShouldLoadIn,
                       let reflectedMusicItem = self.reflectedMusicItem {
                        VStack {
                            HStack {
                                Text("\(reflectedMusicItem.title)")
                                    .font(.system(size: 18, weight: .bold))
                                if reflectedMusicItem.playlistType == .PersonalMix {
                                    Image(systemName: "person.crop.circle").foregroundColor(Color(nsColor: reflectedMusicItem.artwork.bgColour))
                                        .font(.system(size: 18))
                                        .tooltip("Playlist curated by Apple Music")
                                        .modifier(SimpleHoverModifier())
                                }
                            }
                            Text("\(reflectedMusicItem.playlistType == .PersonalMix ? "Made For You" : reflectedMusicItem.artistName)")
                                .foregroundColor(.gray)
                            
                            if let description = reflectedMusicItem.description {
                                Text("\(description)")
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 300)
                            }
                            
                            HStack {
                                MediaActionButton(icon: .Play) {
                                    self.playSync(mediaItem: reflectedMusicItem)
                                }
                                MediaActionButton(icon: .Shuffle) {
                                    self.playSync(mediaItem: reflectedMusicItem, shuffle: true)
                                }
                                addToLibrary
                            }
                        }
                        .padding(.vertical)
                        .isHidden(!animationFinished)
                        .transition(.move(edge: .bottom).animation(.interactiveSpring()))
                    }
                }
                
                Spacer()
                
                if tracksShouldLoadIn {
                    ScrollView(.vertical) {
                        LazyVStack {
                            ForEach(reflectedMusicItem?.tracks ?? [], id: \.id) { track in
                                MediaTrackRepresentable(mediaTrack: track)
                                    .environmentObject(navigationModal)
                                    .environmentObject(mkModal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .transparentScrollbars()
                    .transition(.move(edge: .bottom))
                }
            }
            .task {
                guard let id = self.reflectedMusicItem?.id else { return }
                self.reflectedMusicItem?.tracks = (try? await self.mkModal.AM_API.fetchTracks(id: id, type: self.reflectedMusicItem?.type ?? .AnyMedia)) ?? []
                
                withAnimation(.spring().delay(0.3)) {
                    self.tracksShouldLoadIn = true
                }
            }
            .onAppear {
                self.reflectedMusicItem = mediaItem
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.leading, 30)
            .onDisappear {
                self.reflectedMusicItem = nil
            }
        }
        .enableInjection()
    }
}

struct DetailedView_Previews: PreviewProvider {
    
    @Namespace private static var stubId
    
    static var previews: some View {
        DetailedView(detailedViewParams: DetailedViewParams(mediaItem: MediaItem(data: []), geometryMatching: stubId, originalSize: .zero))
    }
}
