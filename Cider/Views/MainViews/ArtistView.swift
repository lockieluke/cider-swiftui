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
import Inject

struct ArtistView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var navigationModal: NavigationModal
    #if os(macOS)
    @EnvironmentObject private var nativeUtilsWrapper: NativeUtilsWrapper
    #endif
    
    let artistViewParams: ArtistViewParams
    @State private var artist: MediaArtist?
    @State private var readyToDisplay: Bool = false
    @State private var artistBioHeight: CGFloat = .zero
    
    var displayedData: MediaArtist {
        get {
            return MediaArtist(data: [])
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
                            #if os(macOS)
                                .contextMenu {
                                    Button {
                                        self.nativeUtilsWrapper.nativeUtils.copy_string_to_clipboard(artist.id)
                                        
                                    } label: {
                                        Text("Copy ID")
                                    }
                                }
                            #endif
                            
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
                                    MediaPresentable(item: .mediaTrack(latestRelease), maxRelative: geometry.maxRelative.clamped(to: 1000...1300))
                                        .padding(.vertical)
                                }
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Top Songs")
                                    .font(.title2.bold())
                                MediaTableRepresentable(artist.topSongs.map { topSong in .mediaTrack(topSong) })
                                    .environmentObject(ciderPlayback)
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
                                        MediaPresentable(item: .mediaTrack(single), maxRelative: geometry.maxRelative.clamped(to: 1000...1300))
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
                                        MediaArtistPresentable(artist: similarArtist, maxRelative: geometry.maxRelative.clamped(to: 1000...1300))
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
                if let artistData = mediaTrack.artistsData[safe: selectingArtistIndex] {
                    await fetchById(artistData.id)
                }
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
