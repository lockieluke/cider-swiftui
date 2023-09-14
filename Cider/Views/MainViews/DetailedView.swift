//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject
import SDWebImageSwiftUI
import UIImageColors

struct DetailedView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    @State private var size: CGSize = .zero
    @State private var animationFinished: Bool = false
    @State private var descriptionsShouldLoadIn: Bool = false
    @State private var tracks: [MediaTrack] = []
    @State private var tracksShouldLoadIn: Bool = false
    @State private var bgGlowGradientColours = Gradient(colors: [])
    @State private var isInLibrary = false
    @State private var rotationAngle: Double = 0
    
    private let detailedViewParams: DetailedViewParams
    // Has to be done, because this view only accepts two types of MediaDynamic
    private var id, title, artistName, contentRating: String!
    private var artwork: MediaArtwork!
    private var description: MediaDescription!
    private var playlistType: PlaylistType!
    
    init(detailedViewParams: DetailedViewParams) {
        self.detailedViewParams = detailedViewParams
        
        if case .mediaItem(let mediaItem) = detailedViewParams.item {
            id = mediaItem.id
            title = mediaItem.title
            artwork = mediaItem.artwork
            contentRating = mediaItem.contentRating
            artistName = mediaItem.artistName
            description = mediaItem.description
            playlistType = mediaItem.playlistType ?? .Unknown
        } else if case .mediaPlaylist(let mediaPlaylist) = detailedViewParams.item {
            id = mediaPlaylist.id
            title = mediaPlaylist.title
            artwork = mediaPlaylist.artwork
            artistName = mediaPlaylist.curatorName
            description = mediaPlaylist.description
            playlistType = mediaPlaylist.playlistType ?? .Unknown
        }
    }
    
    var addToLibrary: some View {
        Button {
            Task {
                var result: Bool? = nil
                if case .mediaItem(let mediaItem) = detailedViewParams.item {
                    result = await self.mkModal.AM_API.addToLibrary(item: .mediaItem(mediaItem), !self.isInLibrary)
                } else if case .mediaPlaylist(let mediaPlaylist) = detailedViewParams.item {
                    result = await self.mkModal.AM_API.addToLibrary(item: .mediaPlaylist(mediaPlaylist), !self.isInLibrary)
                }
                if result == true {
                    self.isInLibrary.toggle()
                    self.rotationAngle += 45
                }
            }
            
        } label: {
            HStack {
                Image(systemSymbol: .plus)
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(.easeInOut(duration: 0.5), value: rotationAngle)
                
                Text(self.isInLibrary ? "Remove from Library" : "Add to Library")
            }
            .padding(.horizontal)
        }.buttonStyle(.borderless)
            .frame(height: 25)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color("SecondaryColour").opacity(0.5)))
            .modifier(SimpleHoverModifier())
    }
    
    func playSync(item: MediaDynamic, shuffle: Bool = false) {
        Task {
            await self.ciderPlayback.setQueue(item: item)
            await self.ciderPlayback.clearAndPlay(shuffle: shuffle, item: item)
        }
    }
    
    var body: some View {
        let originalSize = self.detailedViewParams.originalSize
        
        PatchedGeometryReader { geometry in
            HStack(spacing: 0) {
                VStack {
                    let sqaureSize = geometry.minRelative * 0.4
                    
                    let cover = WebImage(url: artwork.getUrl(width: 600, height: 600, kind: self.detailedViewParams.coverKind))
                        .onSuccess { image, data, cacheType in
                            image.getColors(quality: .highest) { colours in
                                guard let colours = colours else { return }
                                self.bgGlowGradientColours = Gradient(colors: [Color(platformColor: colours.primary), Color(platformColor: colours.secondary), Color(platformColor: colours.detail), Color(platformColor: colours.background)])
                            }
                        }
                        .resizable()
                        .indicator(.progress)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: sqaureSize, height: sqaureSize, alignment: .center)
                        .clipped()
                        .cornerRadius(5)
                        .background(
                            Rectangle()
                                .background(Color(platformColor: artwork.bgColour))
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(5)
                                .multicolourGlow()
                        )
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
                            rotationAngle = isInLibrary ? 45 : 0
                        }
                        .padding(.vertical, 5)
                    
                    if let animationNamespace = self.detailedViewParams.geometryMatching,
                       let id = self.id {
                        cover.matchedGeometryEffect(id: id, in: animationNamespace)
                    } else {
                        cover
                    }
                    
                    VStack {
                        HStack {
                            Text("\(title)")
                                .font(.system(size: 18, weight: .bold))
                            if contentRating == "explicit" {
                                Image(systemSymbol: .eSquareFill)
                            }
                            if playlistType == .PersonalMix {
                                Image(systemSymbol: .personCropCircle).foregroundColor(Color(platformColor: artwork.bgColour))
                                    .font(.system(size: 18))
                                    .tooltip("Playlist curated by Apple Music")
                                    .modifier(SimpleHoverModifier())
                            }
                        }
                        Text("\(playlistType == .PersonalMix ? "Made For You" : artistName)")
                            .foregroundColor(.gray)
                        
                        
                        Text(description.standard.htmlToString)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                        
                        HStack {
                            MediaActionButton(icon: .Play) {
                                self.playSync(item: self.detailedViewParams.item)
                            }
                            MediaActionButton(icon: .Shuffle) {
                                self.playSync(item: self.detailedViewParams.item, shuffle: true)
                            }
                            addToLibrary
                        }
                    }
                    .padding(.vertical)
                    .isHidden(!animationFinished)
                    .transition(.move(edge: .bottom).animation(.interactiveSpring()))
                }
                
                Spacer()
                
                if tracksShouldLoadIn {
                    ScrollView(.vertical) {
                        LazyVStack {
                            ForEach(tracks, id: \.id) { track in
                                MediaTrackRepresentable(mediaTrack: track)
                            }
                        }
                        .padding(.vertical)
                    }
                    .transparentScrollbars()
                    .transition(.move(edge: .bottom))
                }
            }
            .task {
                print("Opened Detailed View")
                
                switch detailedViewParams.item {
                case .mediaItem(let mediaItem):
                    async let tracksResult = try? self.mkModal.AM_API.fetchTracks(id: mediaItem.id, type: .Album)
                    async let libraryResult = self.mkModal.AM_API.fetchLibraryCatalog(item: .mediaItem(mediaItem))
                    
                    if let fetchedTracks = await tracksResult {
                        self.tracks = fetchedTracks
                    }
                    if let isInLibrary = await libraryResult {
                        self.isInLibrary = isInLibrary
                    }
                    
                case .mediaPlaylist(let mediaPlaylist):
                    async let tracksResult = try? self.mkModal.AM_API.fetchTracks(id: mediaPlaylist.id, type: .Playlist)
                    async let libraryResult = self.mkModal.AM_API.fetchLibraryCatalog(item: .mediaPlaylist(mediaPlaylist))
                    
                    if let fetchedTracks = await tracksResult {
                        self.tracks = fetchedTracks
                    }
                    if let isInLibrary = await libraryResult {
                        self.isInLibrary = isInLibrary
                    }
                default:
                    break
                }
                
                rotationAngle = isInLibrary ? 45 : 0
                withAnimation(.spring().delay(0.3)) {
                    self.tracksShouldLoadIn = true
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.leading, 30)
        }
        .enableInjection()
    }
}

struct DetailedView_Previews: PreviewProvider {
    
    @Namespace private static var stubId
    
    static var previews: some View {
        DetailedView(detailedViewParams: DetailedViewParams(item: .mediaItem(MediaItem(data: [])), geometryMatching: stubId, originalSize: .zero))
    }
}
