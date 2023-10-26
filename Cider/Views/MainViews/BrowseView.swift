//
//  BrowseView.swift
//  Cider
//
//  Created by Sherlock LUK on 28/07/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject

struct BrowseView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    
    @State private var allBrowseData: [MediaBrowseData] = []
    @State private var heroCardData: [MediaBrowseData] = []
    @State private var playlistBrowseData: [MediaBrowseData] = []
    @State private var albumBrowseData: [MediaBrowseData] = []
    @State private var songBrowseData: [MediaBrowseData] = []
    
    @State private var playlists: [MediaPlaylist] = []
    @State private var albums: [MediaItem] = []
    @State private var featuredPlaylists: [MediaPlaylist] = []
    @State private var songs: [MediaTrack] = []
    
    @State private var playlistEditorialTitles: [String] = []
    @State private var albumEditorialTitles: [String] = []
    @State private var songEditorialTitles: [String] = []
    
    @Namespace private var animationNamespace
    
    let heroCardSize: CGSize = CGSize(width: 550, height: 225)
    let coverKindValue: String = "bb"
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                Text("Browse")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                PatchedGeometryReader { geometry in
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 20) {
                            ForEach(heroCardData, id: \.id) { heroCardDataRow in
                                ForEach(heroCardDataRow.items, id: \.self) { item in
                                    HeroCard(
                                        item: item,
                                        geometryMatching: animationNamespace,
                                        originalSize: heroCardSize,
                                        coverKind: coverKindValue,
                                        maxRelative: geometry.maxRelative
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .transparentScrollbars()
                    .padding(.bottom)
                }
                
                MediaShowcaseRow(rowTitle: playlistEditorialTitles[safe: 0] ?? "", items: MediaDynamic.fromPlaylists(playlists))
                MediaShowcaseRow(rowTitle: albumEditorialTitles[safe: 0] ?? "", items: MediaDynamic.fromMediaItems(albums))
                MediaShowcaseRow(rowTitle: albumEditorialTitles[safe: 1] ?? "", items: MediaDynamic.fromPlaylists(featuredPlaylists))
                
                VStack {
                    Text(songEditorialTitles[safe: 0] ?? "")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 15)
                    
                    MediaTableRepresentable(songs.map { song in .mediaTrack(song) })
                        .padding(.bottom)
                }
                .padding(.vertical)
            }
            .padding()
        }
        .transparentScrollbars()
        .task {
            await fetchData()
        }
        .enableInjection()
    }
    
    private func fetchData() async {
        self.allBrowseData = await mkModal.AM_API.fetchBrowse()
        
        self.heroCardData = allBrowseData.filter { $0.kind.rawValue == "316" }
        self.playlistBrowseData = allBrowseData.filter { $0.kind.rawValue == "326" }
        self.albumBrowseData = allBrowseData.filter { $0.kind.rawValue == "387" }
        self.songBrowseData = allBrowseData.filter { $0.kind.rawValue == "327" }
        
        self.playlistEditorialTitles = playlistBrowseData.map { $0.editorialTitle }
        self.albumEditorialTitles = albumBrowseData.map { $0.editorialTitle }
        self.songEditorialTitles = songBrowseData.map { $0.editorialTitle }
        
        await withTaskGroup(of: Void.self) { group in
            for data in playlistBrowseData {
                for item in data.items {
                    group.addTask {
                        do {
                            switch item.kind {
                            case "playlist":
                                let playlistData = try await mkModal.AM_API.fetchPlaylist(id: item.id)
                                DispatchQueue.main.async {
                                    self.playlists.append(playlistData)
                                }
                            case "album":
                                let albumData = try await mkModal.AM_API.fetchAlbum(id: item.id)
                                DispatchQueue.main.async {
                                    self.albums.append(albumData)
                                }
                            default:
                                break
                            }
                        } catch {
                            print("Error occurred while fetching item: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
            for data in albumBrowseData {
                for item in data.items {
                    group.addTask {
                        do {
                            if item.kind == "playlist" {
                                let playlistData = try await mkModal.AM_API.fetchPlaylist(id: item.id)
                                DispatchQueue.main.async {
                                    self.featuredPlaylists.append(playlistData)
                                }
                            }
                        } catch {
                            print("Error occurred while fetching playlist: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
            for data in songBrowseData {
                for item in data.items {
                    group.addTask {
                        do {
                            if item.kind == "song" {
                                let songData = try await mkModal.AM_API.fetchSong(id: item.id)
                                DispatchQueue.main.async {
                                    self.songs.append(songData)
                                }
                            }
                        } catch {
                            print("Error occurred while fetching song: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
}

struct BrowseView_Previews: PreviewProvider {
    static var previews: some View {
        BrowseView()
    }
}
