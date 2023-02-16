//
//  ArtistView.swift
//  Cider
//
//  Created by Sherlock LUK on 23/01/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import AttributedText
import SDWebImageSwiftUI
import InjectHotReload

struct ArtistView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var navigationModal: NavigationModal
    
    let artistViewParams: ArtistViewParams
    @State private var artist: MediaArtist?
    @State private var readyToDisplay: Bool = false
    @State private var artistBioHeight: CGFloat = .zero
    
    var displayedData: MediaArtist {
        get {
            return MediaArtist(data: [])
        }
    }
    
    struct TopSongView: View {
        
        @ObservedObject private var iO = Inject.observer
        
        @EnvironmentObject private var ciderPlayback: CiderPlayback
        
        @State private var isHovering: Bool = false
        @State private var isClicked: Bool = false
        
        private let mediaTrack: MediaTrack
        
        init(_ mediaTrack: MediaTrack) {
            self.mediaTrack = mediaTrack
        }
        
        var body: some View {
            HStack(alignment: .center) {
                WebImage(url: mediaTrack.artwork.getUrl(width: 40, height: 40))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .cornerRadius(5, antialiased: true)
                    .brightness(isHovering ? -0.5 : 0)
                    .overlay {
                        if isHovering {
                            Image(systemName: "play.fill")
                        }
                    }
                Text(mediaTrack.title)
                Spacer()
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .frame(width: 300)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isHovering ? Color("SecondaryColour").opacity(isClicked ? 0.7 : 0.5) : Color.clear)
                    .animation(.interactiveSpring(), value: isHovering || isClicked)
            )
            .onHover { isHovering in
                withAnimation(.easeIn.speed(10)) {
                    self.isHovering = isHovering
                }
            }
            .onTapGesture {
                Task {
                    await self.ciderPlayback.setQueue(item: .mediaTrack(self.mediaTrack))
                    await self.ciderPlayback.clearAndPlay(shuffle: false, item: .mediaTrack(self.mediaTrack))
                }
            }
            .modifier(PressActions(onEvent: { isPressed in
                self.isClicked = isPressed
            }))
            .enableInjection()
        }
        
    }
    
    init(params: ArtistViewParams) {
        self.artistViewParams = params
    }
    
    var body: some View {
        PatchedGeometryReader { geometry in
            ScrollView(.vertical) {
                if let artist = self.artist {
                    VStack {
                        if readyToDisplay {
                            WebImage(url: artist.artwork.getUrl(width: 500, height: 500))
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(.infinity)
                                .frame(width: geometry.minRelative * 0.3, height: geometry.minRelative * 0.3)
                                .frame(minWidth: 50, minHeight: 50)
                                .shadow(radius: 10)
                                .padding(60)
                                .contextMenu {
                                    Button {
                                        NSPasteboard.general.declareTypes([.string], owner: nil)
                                        NSPasteboard.general.setString(artist.id, forType: .string)
                                    } label: {
                                        Text("Copy ID")
                                    }
                                }
                            
                            HStack(alignment: .center) {
                                MediaActionButton(icon: .Play, size: 35)
                                Text(artist.artistName)
                                    .font(.title.bold())
                                    .padding(.horizontal, 10)
                                Spacer()
                                MediaActionButton(icon: .Shuffle, size: 35)
                            }
                            .padding(.horizontal, 30)
                        }
                        
                        HStack(alignment: .top) {
                            if let latestRelease = artist.latestReleases.first {
                                VStack(alignment: .leading) {
                                    Text("Latest Release")
                                        .font(.title2.bold())
                                    MediaPresentable(item: .mediaTrack(latestRelease), maxRelative: 1000)
                                        .padding(.vertical)
                                }
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Top Songs")
                                    .font(.title2.bold())
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], alignment: .center, spacing: 10) {
                                    ForEach(artist.topSongs, id: \.id) { topSong in
                                        TopSongView(topSong)
                                            .environmentObject(ciderPlayback)
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        
                        VStack(alignment: .leading) {
                            Text("Singles")
                                .font(.title2.bold())
                            ScrollView(.horizontal) {
                                LazyHStack {
                                    ForEach(artist.singles, id: \.id) { single in
                                        MediaPresentable(item: .mediaTrack(single), maxRelative: 1000)
                                            .padding(.vertical)
                                    }
                                }
                            }
                            .transparentScrollbars()
                        }
                        .padding(.vertical)
                        
                        VStack(alignment: .leading) {
                            Text("Similar Artists")
                                .font(.title2.bold())
                            
                            ScrollView(.horizontal) {
                                LazyHStack {
                                    ForEach(artist.similarArtists, id: \.id) { similarArtist in
                                        MediaArtistPresentable(artist: similarArtist, maxRelative: 1000)
                                            .environmentObject(navigationModal)
                                            .padding(.vertical)
                                    }
                                }
                            }
                            .transparentScrollbars()
                        }
                        .padding(.vertical)
                        
                        if let artistBio = artist.artistBio {
                            Text("About \(artist.artistName)")
                                .font(.title2.bold())
                            
                            AttributedText(artistBio)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical)
                                .modifier(SimpleHoverModifier())
                        }
                        
                        if let origin = artist.origin {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Hometown")
                                        .font(.title2.bold())
                                    Text("\(origin)")
                                }
                                .modifier(SimpleHoverModifier())
                                
                                VStack(alignment: .leading) {
                                    Text("Born")
                                        .font(.title2.bold())
                                    Text("12th December 2023")
                                }
                                .modifier(SimpleHoverModifier())
                                .padding(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .transparentScrollbars()
        }
        .task {
            let selectingArtistIndex = self.artistViewParams.selectingArtistIndex
            
            let fetchById: (_ id: String) async -> Void = { id in
                do {
                    self.artist = try await self.mkModal.AM_API.fetchArtist(id: id, params: [.TopSongs, .Singles, .LatestRelease, .SimilarAritsts], extendParams: [.artistBio, .origin])
                } catch {
                    print(error)
                }
            }
            
            switch self.artistViewParams.originMediaItem {
                
            case .mediaTrack(let mediaTrack):
                await fetchById(mediaTrack.artistsData[selectingArtistIndex].id)
                break
                
            default:
                if let artist = self.artistViewParams.artist {
                    await fetchById(artist.id)
                }
                break
                
            }
            
            self.readyToDisplay = true
        }
        .enableInjection()
    }
}

struct ArtistView_Previews: PreviewProvider {
    static var previews: some View {
        ArtistView(params: ArtistViewParams(originMediaItem: .mediaTrack(MediaTrack(data: []))))
    }
}
