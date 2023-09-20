//
//  HeroCard.swift
//  Cider
//
//  Created by Monochromish on 10/09/23.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import Inject

struct HeroCard: View {
    
    var item: BrowseItemAttributes
    var geometryMatching: Namespace.ID
    var originalSize: CGSize
    var coverKind: String
    var maxRelative: CGFloat
    
    @ObservedObject private var observer = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var navigationModal: NavigationModal
    
    @State private var isHovering = false
    @State private var artistData: MediaArtist?
    @State private var playlistData: MediaPlaylist?
    @State private var albumData: MediaItem?
    
    func navigateArtist(artistID: String) async {
        do {
            self.artistData = try await self.mkModal.AM_API.fetchArtist(id: artistID)
            self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .artistViewParams(ArtistViewParams(artist: self.artistData!))))
        } catch {
            print("Error navigating to artist's page: \(error)")
        }
    }
    
    func navigateItem(itemID: String, itemKind: String) async {
        do {
            if itemKind == "playlist" {
                self.playlistData = try await self.mkModal.AM_API.fetchPlaylist(id: itemID)
                self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .detailedViewParams(DetailedViewParams(item: .mediaPlaylist(self.playlistData!), geometryMatching: geometryMatching, originalSize: originalSize, coverKind: coverKind))))
                
            } else if itemKind == "album" {
                self.albumData = try await self.mkModal.AM_API.fetchAlbum(id: itemID)
                self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .detailedViewParams(DetailedViewParams(item: .mediaItem(self.albumData!), geometryMatching: geometryMatching, originalSize: originalSize, coverKind: coverKind))))
            }
        } catch {
            print("Error navigating: \(error)")
        }
    }
    
    var body: some View {
        let scale = max(maxRelative * 0.00075, 0.8)
        
        VStack(alignment: .leading) {
            HStack {
                Text(item.designBadge)
                    .font(.footnote)
                    .fontWeight(.light)
                    .shadow(radius: 5)
                    .foregroundColor(.gray)
                Spacer()
            }
            Text(item.name)
                .font(.title)
                .lineLimit(1)
                .onTapGesture {
                    Task {
                        await navigateItem(itemID: item.id, itemKind: item.kind)
                    }
                }.modifier(SimpleHoverModifier())
            
            Group {
                if !item.artistName.isEmpty {
                    Text(item.artistName)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .shadow(radius: 5)
                        .foregroundColor(.gray)
                } else {
                    Text(" ")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .shadow(radius: 5)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: 530 * scale - 30, alignment: .leading)
            .onTapGesture {
                Task {
                    await navigateArtist(artistID: item.artistId)
                }
            }
            .modifier(SimpleHoverModifier())
            
            WebImage(url: URL(string: item.subscriptionHero))
                .resizable()
                .frame(width: 530 * scale, height: 135 * scale, alignment: .leading)
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .shadow(radius: 8)
                .brightness(isHovering ? -0.1 : 0)
                .animation(.easeIn(duration: 0.15), value: isHovering)
                .onHover { isHovering in
                    self.isHovering = isHovering
                }
                .overlay {
                    Group {
                        if !item.subscriptionHero.isEmpty {
                            Text(item.plainEditorialNotes)
                                .foregroundStyle(.white)
                                .frame(maxWidth: 530 * 0.75 * scale, alignment: .leading)
                        }
                    }
                    .shadow(radius: 30)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.horizontal)
                    .padding(.vertical, 15)
                }
                .onTapGesture {
                    Task {
                        await navigateItem(itemID: item.id, itemKind: item.kind)
                    }
                }
                .modifier(SimpleHoverModifier())
        }
        .enableInjection()
    }
}
