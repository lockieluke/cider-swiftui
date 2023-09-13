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
    
    @State private var prefetechedAttributes = false
    @State private var isInLibrary = false
    @State private var rating: MediaRatings = .Neutral
    
    private let item: MediaDynamic
    
    init(item: MediaDynamic) {
        self.item = item
    }
    
    private var loveActionText: String {
        return rating == .Liked ? "Unlove" : "Love"
    }
    
    private var dislikeActionText: String {
        return rating == .Disliked ? "Undo Suggest Less" : "Suggest Less"
    }
    
    private var menu: [ContextMenuArg] {
        var menuItems = [
            ContextMenuArg(loveActionText, id: "love", disabled: rating == .Disliked),
            ContextMenuArg(dislikeActionText, id: "dislike", disabled: rating == .Liked),
            ContextMenuArg(isInLibrary ? "Remove from Library" : "Add to Library", id: "mod-library"),
            ContextMenuArg("Add to Playlist"),
            ContextMenuArg(),
            ContextMenuArg("Play Next"),
            ContextMenuArg("Play Later")
        ]
        
#if DEBUG
        menuItems += [
            ContextMenuArg(),
            ContextMenuArg("Copy ID")
        ]
#endif
        
        return menuItems
    }
    
    func body(content: Content) -> some View {
        content
#if canImport(AppKit)
            .captureMouseEvent(.MouseEntered) {
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
            
        case "dislike":
            rating = (rating == .Disliked) ? .Neutral : .Disliked
            _ = await mkModal.AM_API.setRating(item: item, rating: rating)
            
        case "mod-library":
            if await mkModal.AM_API.addToLibrary(item: item, !isInLibrary) {
                isInLibrary.toggle()
            }
            
#if os(macOS)
        case "copy-id":
            NativeUtilsWrapper.nativeUtilsGlobal.copy_string_to_clipboard(item.id)
#endif
            
        default:
            break
        }
    }
}
