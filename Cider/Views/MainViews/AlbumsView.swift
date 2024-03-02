//
//  AlbumsView.swift
//  Cider
//
//  Created by Sherlock LUK on 02/03/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject
import Lottie
import Throttler

struct AlbumsView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    
    @State private var albums: [MediaDynamic] = []
    @State private var searchResultItems: [MediaDynamic] = []
    @State private var isFetching: Bool = false
    @State private var isSearching: Bool = false
    @State private var searchTerm: String = ""
    
    var body: some View {
        PatchedGeometryReader { geometry in
            VStack {
                HStack {
                    Text("Albums")
                        .font(.title2)
                        .bold()
                    
                    Spacer()
                        .frame(maxWidth: .infinity)
                    
                    TextField("Search", text: $searchTerm)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay {
                            if isSearching {
                                HStack {
                                    Spacer()
                                    Button {
                                        self.searchTerm = ""
                                    } label: {
                                        Image(systemName: "multiply.circle.fill")
                                    }
                                    .buttonStyle(.borderless)
                                    .foregroundColor(.secondary)
                                    .padding(.trailing, 4)
                                }
                            }
                        }
                        .frame(width: geometry.maxRelative * 0.2)
                    
                    if isFetching {
                        LottieView(animation: try! .from(data: precompileIncludeData("@/Cider/Resources/CiderSpinner.json")))
                            .playing(loopMode: .loop)
                            .clipShape(Rectangle())
                            .frame(width: 15, height: 15)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 5)
                
                ScrollView {
                    PatchedGeometryReader { geometry in
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], alignment: .center, spacing: 50) {
                            if !isSearching {
                                ForEach(albums, id: \.id) { item in
                                    MediaPresentable(item: item, maxRelative: geometry.maxRelative.clamped(to: 1000...1100))
                                        .task {
                                            if self.albums.last?.id == item.id {
                                                self.isFetching = true
                                                let newItems = await self.mkModal.AM_API.fetchRecentlyAdded(offset: self.albums.count)
                                                self.albums.append(contentsOf: newItems)
                                                self.isFetching = false
                                            }
                                        }
                                }
                            } else {
                                ForEach(searchResultItems, id: \.id) { item in
                                    MediaPresentable(item: item, maxRelative: geometry.maxRelative.clamped(to: 1000...1100))
                                }
                            }
                        }
    
                        Spacer()
                            .frame(height: 20)
                    }
                }
                .transparentScrollbars()
            }
            .task {
                self.isFetching = true
                self.albums = await self.mkModal.AM_API.fetchLibraryAlbums()
                self.isFetching = false
            }
            .onChange(of: searchTerm) { searchTerm in
                self.searchResultItems = []
                if searchTerm.isEmpty {
                    self.isSearching = false
                    return
                }
                self.isSearching = true
    
                Debouncer.debounce(shouldRunImmediately: true) {
                    Task {
                        self.isFetching = true
                        self.searchResultItems = (await self.mkModal.AM_API.searchRecentlyAdded(query: searchTerm)).filter { $0.singularType == "library-album" }
                        self.isFetching = false
                    }
                }
            }
        }
        .enableInjection()
    }
}

#Preview {
    AlbumsView()
}
