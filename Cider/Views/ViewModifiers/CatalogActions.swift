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
    
    @State private var prefetchedRatings = false
    @State private var ratings: MediaRatings = .Disliked
    
    private let item: MediaDynamic
    
    init(item: MediaDynamic) {
        self.item = item
    }
    
    private var ratingsPresentableText: String {
        get {
            switch self.ratings {
                
            case .Disliked, .Neutral:
                return "Love"
                
            case .Liked:
                return "Unlove"
                
            }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .captureMouseEvent(.MouseEntered) {
                if !self.prefetchedRatings {
                    Task {
                        self.ratings = await self.mkModal.AM_API.fetchRatings(item: self.item)
                        self.prefetchedRatings = true
                    }
                }
            }
            .contextMenu([
                ContextMenuArg(ratingsPresentableText),
                ContextMenuArg("Add to Library"),
                ContextMenuArg("Add to Playlist"),
                ContextMenuArg(),
                ContextMenuArg("Play Next"),
                ContextMenuArg("Play Later")
            ],  { id in
                Task {
                    if id == self.ratingsPresentableText.lowercased() {
                        let newRatings: MediaRatings = self.ratings == .Liked ? .Neutral : .Liked
                        self.ratings = await self.mkModal.AM_API.setRatings(item: self.item, ratings: newRatings)
                    }
                }
            })
    }
    
}
