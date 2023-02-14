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
    
    @State private var searchResults: SearchResults?
    
    var body: some View {
        ScrollView(.vertical) {
            VStack {
                Text("**Top Results for** *\(searchModal.currentSearchText)*")
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom)
                
                Text("Artists")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(searchResults?.artists ?? [], id: \.id) { artist in
                            MediaArtistPresentable(artist: artist, maxRelative: 1000)
                                .environmentObject(navigationModal)
                        }
                    }
                }
                .transparentScrollbars()
                
                Text("Songs")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(searchResults?.tracks ?? [], id: \.id) { track in
                            MediaPresentable(item: .mediaTrack(track), maxRelative: 1000)
                                .padding(.vertical)
                        }
                    }
                }
                .transparentScrollbars()
                
                Text("Albums")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(searchResults?.albums ?? [], id: \.id) { album in
                            MediaPresentable(item: .mediaItem(album), maxRelative: 1000, geometryMatched: false)
                                .environmentObject(ciderPlayback)
                                .environmentObject(navigationModal)
                                .padding(.vertical)
                        }
                    }
                }
                .transparentScrollbars()
                
                Spacer()
            }
            .padding()
        }
        .transparentScrollbars()
        .onAppear {
            Task {
                self.searchResults = await self.mkModal.AM_API.fetchSearchResults(term: self.searchModal.currentSearchText, types: [.artists, .songs, .albums])
            }
        }
        .enableInjection()
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
