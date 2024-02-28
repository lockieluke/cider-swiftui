//
//  CatalogActions.swift
//  Cider
//
//  Created by Sherlock LUK on 02/03/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftUI

struct CatalogActions: ViewModifier {
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var toastModal: ToastModal
    
    @State private var prefetechedAttributes = false
    @State private var isInLibrary = false
    @State private var rating: MediaRatings = .Neutral
    @State private var albumData: MediaItem?
    #if DEBUG
    @State private var showingInspectModal = false
    #endif
    
    @Namespace private var animationNamespace
    
    private let item: MediaDynamic
    private let isNowPlaying: Bool
    
    init(item: MediaDynamic, isNowPlaying: Bool = false) {
        self.item = item
        self.isNowPlaying = isNowPlaying
    }
    
    private var loveActionText: String {
        return rating == .Liked ? "Unlove" : "Love"
    }
    
    private var dislikeActionText: String {
        return rating == .Disliked ? "Undo Suggest Less" : "Suggest Less"
    }
    
    private var itemTypeText: String {
        return item.type == "songs" ? "Album" :
               item.type == "albums" ? "Album" :
               "Playlist"
    }
    
    private var menu: [ContextMenuArg] {
        var menuItems = [
            ContextMenuArg(loveActionText, id: "love", disabled: rating == .Disliked),
            ContextMenuArg(dislikeActionText, id: "dislike", disabled: rating == .Liked),
            ContextMenuArg(isInLibrary ? "Remove from Library" : "Add to Library", id: "mod-library"),
            ContextMenuArg("Go to \(itemTypeText)", id: "nav-item", visible: (item.albumId?.isEmpty == false)),
            ContextMenuArg("Add to Playlist")
        ]
        
        if !self.isNowPlaying {
            menuItems += [
                ContextMenuArg(),
                ContextMenuArg("Play Next"),
                ContextMenuArg("Play Later")
            ]
        }
        
#if DEBUG
        menuItems += [
            ContextMenuArg(),
            ContextMenuArg("Copy ID"),
            ContextMenuArg("Inspect")
        ]
#endif
        
        return menuItems
    }
    
    func body(content: Content) -> some View {
        content
#if canImport(AppKit)
            .onHover { isHovering in
                Task {
                    if !prefetechedAttributes {
                        rating = await mkModal.AM_API.fetchRating(item: item)
                        if let inLibrary = await mkModal.AM_API.fetchLibraryCatalog(item: item) {
                            isInLibrary = inLibrary
                        }
                        prefetechedAttributes = true
                    }
                }
            }
#endif
        #if DEBUG
            .popover(isPresented: $showingInspectModal) {
                VStack {
                    Text("Title: \(item.title)")
                    Text("Type: \(item.type)")
                }
                .padding()
            }
        #endif
            .contextMenu(menu, { id in
                Task {
                    await handleMenuAction(withId: id)
                }
            })
        
    }
    
    private func handleMenuAction(withId id: String) async {
        switch id {
        case "love":
            rating = (rating == .Liked) ? .Neutral : .Liked
            _ = await mkModal.AM_API.setRating(item: item, rating: rating)
            self.toastModal.showToast(toast: ToastModal.Toast(title: rating == .Liked ? "Loved" : rating == .Neutral ? "Unloved" : "", subtitle: "\(rating == .Liked ? "Added" : rating == .Neutral ? "Removed" : "") **\(item.title)** \(rating == .Liked ? "to" : rating == .Neutral ? "from" : "") Loved", icon: rating == .Liked ? .heartFill : rating == .Neutral ? .heartSlashFill : nil, duration: 2))
            
        case "dislike":
            rating = (rating == .Disliked) ? .Neutral : .Disliked
            _ = await mkModal.AM_API.setRating(item: item, rating: rating)
            self.toastModal.showToast(toast: ToastModal.Toast(title: "Disliked", subtitle: "Disliked **\(item.title)**", icon: .heartSlashFill, duration: 2))
            
        case "mod-library":
            if await mkModal.AM_API.addToLibrary(item: item, !isInLibrary) {
                isInLibrary.toggle()
            }
            self.toastModal.showToast(toast: ToastModal.Toast(title: "\(isInLibrary ? "Added to" : "Removed from") Library", subtitle: "\(isInLibrary ? "Added **\(item.title)** to" : "Removed **\(item.title)** from") Library", icon: isInLibrary ? .plus : .xCircle, duration: 2, colour: isInLibrary ? .green : .pink))
            
        case "nav-item":
            do {
            if item.type == "playlists" {
                self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .detailedViewParams(DetailedViewParams(item: item, geometryMatching: animationNamespace, originalSize: CGSize(width: 550, height: 225), coverKind: "bb"))))
            } else if item.type == "albums" {
                self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .detailedViewParams(DetailedViewParams(item: item, geometryMatching: animationNamespace, originalSize: CGSize(width: 550, height: 225), coverKind: "bb"))))
            } else if item.type == "songs", let albumId = item.albumId {
                self.albumData = try await self.mkModal.AM_API.fetchAlbum(id: albumId)
                self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .detailedViewParams(DetailedViewParams(item: .mediaItem(self.albumData!), geometryMatching: animationNamespace, originalSize: CGSize(width: 550, height: 225), coverKind: "bb"))))
            }
            } catch {
                print("Error navigating: \(error)")
            }

#if os(macOS) && DEBUG
        case "copy-id":
            NativeUtilsWrapper.nativeUtilsGlobal.copy_string_to_clipboard(item.id)
            
        case "inspect":
            self.showingInspectModal = true
            break
#endif
            
        default:
            break
        }
    }
}
