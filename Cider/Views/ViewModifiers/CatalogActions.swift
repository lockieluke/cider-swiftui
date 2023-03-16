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
    @State private var libraryId: String?
    @State private var ratings: MediaRatings = .Disliked
    
    private let item: MediaDynamic
    
    init(item: MediaDynamic) {
        self.item = item
    }
    
    private var ratingsPresentableText: String {
        switch self.ratings {
            
        case .Disliked, .Neutral:
            return "Love"
            
        case .Liked:
            return "Unlove"
            
        }
    }
    
    private var menu: [ContextMenuArg] {
        var m = [
            ContextMenuArg(ratingsPresentableText, id: "love"),
            ContextMenuArg(self.isInLibrary ? "Remove from Library" : "Add to Library", id: "mod-library"),
            ContextMenuArg("Add to Playlist"),
            ContextMenuArg(),
            ContextMenuArg("Play Next"),
            ContextMenuArg("Play Later")
        ]
        
        #if DEBUG
        m += [
            ContextMenuArg(),
            ContextMenuArg("Copy ID")
        ]
        #endif
        
        return m
    }
    
    func body(content: Content) -> some View {
        content
            .captureMouseEvent(.MouseEntered) {
                Task {
                    if !self.prefetechedAttributes {
                        self.ratings = await self.mkModal.AM_API.fetchRatings(item: self.item)
                        if let (isInLibrary, libraryId) = await self.mkModal.AM_API.fetchLibraryCatalog(item: self.item) {
                            self.isInLibrary = isInLibrary
                            self.libraryId = libraryId
                        }
                        self.prefetechedAttributes = true
                    }
                }
            }
            .contextMenu(menu,  { id in
                Task {
                    switch id {
                        
                    case "love":
                        let newRatings: MediaRatings = self.ratings == .Liked ? .Neutral : .Liked
                        self.ratings = await self.mkModal.AM_API.setRatings(item: self.item, ratings: newRatings)
                        break
                        
                    case "mod-library":
                        if let libraryId = self.libraryId {
                            await self.mkModal.AM_API.addToLibray(item: self.item, libraryId: libraryId, !self.isInLibrary)
                            self.isInLibrary.toggle()
                        }
                        break
                        
                    case "copy-id":
                        NSPasteboard.general.declareTypes([.string], owner: nil)
                        NSPasteboard.general.setString(self.item.id, forType: .string)
                        break
                        
                    default:
                        break
                        
                    }
                }
            })
    }
    
}
