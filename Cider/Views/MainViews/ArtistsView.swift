//
//  ArtistsView.swift
//  Cider
//
//  Created by Sherlock LUK on 03/03/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject
import Lottie
import SplitView
import NukeUI

struct ArtistPresentable: View {
    
    @EnvironmentObject private var navigationModal: NavigationModal
    
    @State private var isHovering: Bool = false
    
    private let artist: MediaLibraryArtist
    private let isSelected: Bool
    private let onTapGesture: (() -> Void)?
    
    init(artist: MediaLibraryArtist, isSelected: Bool = false, _ onTapGesture: (() -> Void)? = nil) {
        self.artist = artist
        self.isSelected = isSelected
        self.onTapGesture = onTapGesture
    }
    
    var body: some View {
        Button {
            self.onTapGesture?()
        } label: {
            HStack(spacing: 15) {
                LazyImage(url: artist.artwork.getUrl(width: 50, height: 50)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .frame(width: 50, height: 50)
                            .scaledToFit()
                    }
                    
                    Color.clear
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                Text(artist.artistName)
                    .font(.title3)
                    .bold()
                    .frame(maxWidth: .infinity)
            }
            .padding()
            .background {
                Rectangle()
                    .fill(isHovering || isSelected ? Color.primary.opacity(0.5) : Color.clear)
            }
        }
        .buttonStyle(.plain)
        .whenHovered { isHovering in
            if self.navigationModal.currentRootStack == .Artists && self.navigationModal.viewsStack.filter ({ $0.rootStackOrigin == .Artists }).isEmpty {
                self.isHovering = isHovering
            }
        }
    }
}

struct ArtistsView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var navigationModal: NavigationModal
    
    @State private var artists: [MediaLibraryArtist] = []
    @State private var selectedArtist: MediaLibraryArtist?
    @State private var artistAlbums: [MediaDynamic] = []
    @State private var isFetching: Bool = false
    
    private func fetchArtists() async {
        self.isFetching = true
        self.artists.append(contentsOf: await self.mkModal.AM_API.fetchLibraryArtists(limit: 25, offset: self.artists.count, sortBy: .name, isAscending: true))
        self.isFetching = false
    }
    
    var body: some View {
        PatchedGeometryReader { geometry in
            VStack {
                HStack {
                    Text("Artists")
                        .font(.title2)
                        .bold()
                    
                    Spacer()
                        .frame(maxWidth: .infinity)
                    
                    if isFetching {
                        LottieView(animation: try! .from(data: precompileIncludeData("@/Cider/Resources/CiderSpinner.json")))
                            .playing(loopMode: .loop)
                            .clipShape(Rectangle())
                            .frame(width: 15, height: 15)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 5)
                
                HSplit(left: {
                    ScrollView {
                        LazyVStack {
                            ForEach(artists, id: \.id) { artist in
                                let isSelected = artist.id == selectedArtist?.id
                                
                                ArtistPresentable(artist: artist, isSelected: isSelected) {
                                    self.selectedArtist = artist
                                    Task {
                                        self.artistAlbums = await self.mkModal.AM_API.fetchLibraryArtistsAlbums(id: artist.id)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .task {
                                    if self.artists.last?.id == artist.id {
                                        await self.fetchArtists()
                                    }
                                }
                            }
                        }
                    }
                    .transparentScrollbars()
                }, right: {
                    if let selectedArtist = self.selectedArtist {
                        VStack {
                            HStack(alignment: .center, spacing: 15) {
                                LazyImage(url: selectedArtist.artwork.getUrl(width: 50, height: 50)) { state in
                                    if let image = state.image {
                                        image
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .scaledToFit()
                                    }
                                    
                                    Color.clear
                                }
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                                
                                Text(selectedArtist.artistName)
                                    .font(.title)
                                    .bold()
                                
                                Spacer()
                                
                                Button {
                                    Task {
                                        if let artist = try? await self.mkModal.AM_API.fetchArtist(id: selectedArtist.artistId) {
                                            self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .artistViewParams(ArtistViewParams(artist: artist))))
                                        }
                                    }
                                } label: {
                                    Text("Show in Apple Music")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.pink)
                            }
                            .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 15) {
                                ForEach(artistAlbums, id: \.id) { album in
                                    MediaPresentable(item: album, maxRelative: geometry.maxRelative.clamped(to: 1000...1300))
                                }
                            }
                            .padding(.vertical)
                            
                            Spacer()
                        }
                    } else {
                        Text("Select an artist to view their albums")
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.secondary)
                    }
                })
                .fraction(usingUserDefaults(0.25, key: "artistViewSplitFraction"))
                .constraints(minPFraction: 0.25, minSFraction: 0.5)
                .styling(color: .primary.opacity(0.5), inset: .zero, visibleThickness: 2)
            }
        }
        .task {
            await self.fetchArtists()
        }
        .enableInjection()
    }
}

#Preview {
    ArtistsView()
}
