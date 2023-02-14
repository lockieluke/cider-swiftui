//
//  SearchView.swift
//  Cider
//
//  Created by Sherlock LUK on 13/02/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import InjectHotReload

struct SearchView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var searchModal: SearchModal
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    var body: some View {
        ScrollView(.vertical) {
            if let searchResults = self.searchModal.searchResults {
                VStack {
                    Text("**Top Results for** *\(searchModal.currentSearchText)*")
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom)
                    
                    if let artists = searchResults.artists, !artists.isEmpty {
                        Text("Artists")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ScrollView(.horizontal) {
                            LazyHStack {
                                ForEach(artists, id: \.id) { artist in
                                    MediaArtistPresentable(artist: artist, maxRelative: 1000)
                                        .environmentObject(navigationModal)
                                }
                            }
                        }
                        .transparentScrollbars()
                    }
                    
                    if let tracks = searchResults.tracks, !tracks.isEmpty {
                        Text("Songs")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ScrollView(.horizontal) {
                            LazyHStack {
                                ForEach(tracks, id: \.id) { track in
                                    MediaPresentable(item: .mediaTrack(track), maxRelative: 1000)
                                        .padding(.vertical)
                                }
                            }
                        }
                        .transparentScrollbars()
                    }
                    
                    if let albums = searchResults.albums, !albums.isEmpty {
                        Text("Albums")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ScrollView(.horizontal) {
                            LazyHStack {
                                ForEach(albums, id: \.id) { album in
                                    MediaPresentable(item: .mediaItem(album), maxRelative: 1000, geometryMatched: false)
                                        .environmentObject(ciderPlayback)
                                        .environmentObject(navigationModal)
                                        .padding(.vertical)
                                }
                            }
                        }
                        .transparentScrollbars()
                    }
                    
                    if let playlists = searchResults.playlists, !playlists.isEmpty {
                        Text("Playlists")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ScrollView(.horizontal) {
                            LazyHStack {
                                ForEach(playlists, id: \.id) { playlist in
                                    MediaPresentable(item: .mediaPlaylist(playlist), maxRelative: 1000, geometryMatched: false)
                                        .environmentObject(ciderPlayback)
                                        .environmentObject(navigationModal)
                                        .padding(.vertical)
                                }
                            }
                        }
                        .transparentScrollbars()
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .transparentScrollbars()
        .task {
            
        }
        .enableInjection()
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
