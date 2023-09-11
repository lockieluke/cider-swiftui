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
        PatchedGeometryReader { geometry in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    Text("Browse")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom)
                    
                    ScrollView(.horizontal) {
                        LazyHStack {
                            ForEach(heroCardData, id: \.id) { heroCardDataRow in
                                ForEach(heroCardDataRow.items, id: \.self) { item in
                                    HeroCard(
                                        item: item,
                                        geometryMatching: animationNamespace,
                                        originalSize: heroCardSize,
                                        coverKind: coverKindValue                                    )
                                    .frame(width: heroCardSize.width, height: heroCardSize.height)
                                }
                            }
                        }
                    }
                    .transparentScrollbars()
                    .padding(.bottom)
                    
                    VStack {
                        Text(playlistEditorialTitles[safe: 0] ?? "")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 15)
                        ScrollView([.horizontal]) {
                            LazyHStack {
                                ForEach(playlists, id: \.id) { playlist in
                                    MediaPresentable(item: .mediaPlaylist(playlist), maxRelative: geometry.maxRelative.clamped(to: 1000...1300), geometryMatched: true)
                                        .padding()
                                }
                            }
                        }
                        .transparentScrollbars()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom)
                    }
                    
                    VStack {
                        Text(albumEditorialTitles[safe: 0] ?? "")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 15)
                        ScrollView([.horizontal]) {
                            LazyHStack {
                                ForEach(albums, id: \.id) { album in
                                    MediaPresentable(item: .mediaItem(album), maxRelative: geometry.maxRelative.clamped(to: 1000...1300), geometryMatched: true)
                                        .padding()
                                }
                            }
                        }
                        .transparentScrollbars()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom)
                    }
                    
                    VStack {
                        Text(albumEditorialTitles[safe: 1] ?? "")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 15)
                        ScrollView([.horizontal]) {
                            LazyHStack {
                                ForEach(featuredPlaylists, id: \.id) { playlist in
                                    MediaPresentable(item: .mediaPlaylist(playlist), maxRelative: geometry.maxRelative.clamped(to: 1000...1300), geometryMatched: true)
                                        .padding()
                                }
                            }
                        }
                        .transparentScrollbars()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom)
                    }
                    
                    VStack {
                        Text(songEditorialTitles[safe: 0] ?? "")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 15)
                        
                        MediaTableRepresentable(songs.map { song in .mediaTrack(song) })
                            .padding(.bottom)
                    }
                }
                .padding()
            }
            .transparentScrollbars()
            .task {
                await fetchData()
            }
        }
    }
    
    private func fetchData() async {
        allBrowseData = await mkModal.AM_API.fetchBrowse()
        
        heroCardData = allBrowseData.filter { $0.kind.rawValue == "316" }
        playlistBrowseData = allBrowseData.filter { $0.kind.rawValue == "326" }
        albumBrowseData = allBrowseData.filter { $0.kind.rawValue == "387" }
        songBrowseData = allBrowseData.filter { $0.kind.rawValue == "327" }
        
        playlistEditorialTitles = playlistBrowseData.map { $0.editorialTitle }
        albumEditorialTitles = albumBrowseData.map { $0.editorialTitle }
        songEditorialTitles = songBrowseData.map { $0.editorialTitle }
        
        await withTaskGroup(of: Void.self) { group in
            for data in playlistBrowseData {
                for item in data.items {
                    group.addTask {
                        do {
                            switch item.kind {
                            case "playlist":
                                let playlistData = try await mkModal.AM_API.fetchPlaylist(id: item.id)
                                DispatchQueue.main.async {
                                    playlists.append(playlistData)
                                }
                            case "album":
                                let albumData = try await mkModal.AM_API.fetchAlbum(id: item.id)
                                DispatchQueue.main.async {
                                    albums.append(albumData)
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
                                    featuredPlaylists.append(playlistData)
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
                                    songs.append(songData)
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

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}
