//
//  SongsView.swift
//  Cider
//
//  Created by Sherlock LUK on 29/02/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject
import Lottie
import Tabler
import SDWebImageSwiftUI
import Throttler

struct SongsView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var navigationModal: NavigationModal
    
    @State private var artworkHovered: String?
    @State private var itemHovered: String?
    
    @State private var songs: [MediaDynamic] = []
    @State private var isFetching: Bool = false
    
    @State private var searchResultItems: [MediaDynamic] = []
    @State private var isSearching: Bool = false
    @State private var searchTerm: String = ""
    
    @State private var sortBy: AMAPI.LibrarySortBy = .dataAdded
    @State private var isAscending: Bool = false
    
    private func fetchSongs() async {
        self.isFetching = true
        self.songs.append(contentsOf: await self.mkModal.AM_API.fetchLibrarySongs(limit: 50, offset: self.songs.count, sortBy: self.sortBy, isAscending: self.isAscending))
        self.isFetching = false
    }
    
    private func refetchSongs() async {
        self.isFetching = true
        self.songs = await self.mkModal.AM_API.fetchLibrarySongs(limit: self.songs.count, offset: 0, sortBy: sortBy, isAscending: self.isAscending)
        self.isFetching = false
    }
    
    var body: some View {
        PatchedGeometryReader { geometry in
            VStack {
                HStack {
                    Text("Songs")
                        .bold()
                        .font(.title2)
                    
                    Spacer()
                        .frame(maxWidth: .infinity)
                    
                    Picker("Sort By", selection: $sortBy) {
                        Text("Date Added").tag(AMAPI.LibrarySortBy.dataAdded)
                        Text("Name").tag(AMAPI.LibrarySortBy.name)
                    }
                    .frame(width: geometry.maxRelative * 0.17)
                    
                    Picker("Sort Order", selection: $isAscending) {
                        Text("Ascending").tag(true)
                        Text("Descending").tag(false)
                    }
                    .frame(width: geometry.maxRelative * 0.175)
                    
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
                .padding(.top, 5)
                
                let gridItems = [GridItem(.flexible(maximum: 50), alignment: .leading), GridItem(.flexible(minimum: 120, maximum: 130), alignment: .leading), GridItem(.flexible(minimum: 100), alignment: .leading)]
                
                TablerStack(.init(tablePadding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)), header: { ctx in
                    LazyVGrid(columns: gridItems) {
                        Group {
                            Text("")
                            Text("Name")
                            Text("Artist Name")
                        }
                        .font(.subheadline.bold())
                    }
                }, row: { song in
                    let artworkHovered = artworkHovered == song.id
                    let isHovered = itemHovered == song.id
                    let isPlaying = song.id == ciderPlayback.nowPlayingState.item?.id
                    
                    LazyVGrid(columns: gridItems) {
                        WebImage(url: song.artwork.getUrl(width: 30, height: 30))
                            .resizable()
                            .frame(width: 30, height: 30)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .onHover { isHovering in
                                self.artworkHovered = isHovering ? song.id : nil
                            }
                            .overlay {
                                if isPlaying {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(.black.opacity(0.5))
                                        .overlay {
                                            Image(systemSymbol: .play)
                                                .foregroundColor(.white)
                                                .background(Color.black.opacity(0.5))
                                        }
                                } else {
                                    if artworkHovered {
                                        Button {
                                            Task {
                                                await self.ciderPlayback.playbackEngine.setQueue(item: song)
                                                await self.ciderPlayback.clearAndPlay()
                                            }
                                        } label: {
                                            Image(systemSymbol: .playFill)
                                                .foregroundColor(.white)
                                                .padding(5)
                                                .background(Color.black.opacity(0.5))
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                        .padding(5)
                                    }
                                }
                            }
                        Text(song.title)
                        Text(song.artistName)
                    }
                    .onHover { isHovering in
                        self.itemHovered = isHovering ? song.id : nil
                    }
                    .modifier(CatalogActions(item: song, isNowPlaying: isPlaying))
                    .background(isHovered ? Color.black.opacity(0.1) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: isHovered ? 5 : 0))
                    .if(!isSearching) { view in
                        view
                            .task {
                                if song.id == self.songs.last?.id {
                                    await self.fetchSongs()
                                }
                            }
                    }
                }, rowBackground: { _ in
                    Color.clear
                }, results: isSearching ? searchResultItems : songs)
                .transparentScrollbars()
                .padding(.horizontal, 10)
            }
            .task {
                await self.fetchSongs()
            }
        }
        .onChange(of: sortBy) { sortBy in
            Task {
                await self.refetchSongs()
            }
        }
        .onChange(of: isAscending) { isAscending in
            Task {
                await self.refetchSongs()
            }
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
                    self.searchResultItems = await self.mkModal.AM_API.searchRecentlyAdded(query: searchTerm)
                    self.isFetching = false
                }
            }
        }
        .isHidden(navigationModal.currentRootStack != .Songs)
        .enableInjection()
    }
}

#Preview {
    SongsView()
}
