//
//  SearchView.swift
//  Cider
//
//  Created by Sherlock LUK on 13/02/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject

struct SearchView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var searchModal: SearchModal
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    var body: some View {
        PatchedGeometryReader { geometry in
            ScrollView(.vertical) {
                VStack {
                    Text("**Search Results for** *\(searchModal.currentSearchText)*")
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom)
                    
                    if let searchResults = self.searchModal.searchResults, !searchResults.isEmpty {
                        if let artists = searchResults.artists, !artists.isEmpty {
                            Text("Artists")
                                .font(.title2.bold())
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ScrollView(.horizontal) {
                                LazyHStack {
                                    ForEach(artists, id: \.id) { artist in
                                        MediaArtistPresentable(artist: artist, maxRelative: geometry.maxRelative.clamped(to: 1000...1300))
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
                                        MediaPresentable(item: .mediaTrack(track), maxRelative: geometry.maxRelative.clamped(to: 1000...1300))
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
                                        MediaPresentable(item: .mediaItem(album), maxRelative: geometry.maxRelative.clamped(to: 1000...1300), geometryMatched: false)
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
                                        MediaPresentable(item: .mediaPlaylist(playlist), maxRelative: geometry.maxRelative.clamped(to: 1000...1300), geometryMatched: false)
                                            .environmentObject(ciderPlayback)
                                            .environmentObject(navigationModal)
                                            .padding(.vertical)
                                    }
                                }
                            }
                            .transparentScrollbars()
                        }
                        
                        Spacer()
                    } else if searchModal.isLoadingResults {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(maxHeight: .infinity, alignment: .center)
                    } else {
                        Text("""
                             **No Results**
                             Try a new search and check your spellings
                             """)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: .infinity, alignment: .center)
                    }
                }
                .padding()
            }
            .transparentScrollbars()
        }
        .enableInjection()
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
