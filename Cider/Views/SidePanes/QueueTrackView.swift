//
//  QueueItemView.swift
//  Cider
//
//  Created by Sherlock LUK on 24/03/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import NukeUI
import Inject

struct QueueTrackView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @State private var isHovering = false
    @State private var isClicking = false
    
    @Binding private var allowReordering: Bool
    
    private let mediaTrack: MediaTrack
    private let onReordering: ((_ reorderingIndex: Int?) -> Void)?
    private let onPlay: (() -> Void)?
    
    init(track: MediaTrack, allowReordering: Binding<Bool> = .constant(true), onReordering: ((_ reorderingIndex: Int?) -> Void)? = nil, onPlay: (() -> Void)? = nil) {
        self.mediaTrack = track
        self._allowReordering = allowReordering
        self.onReordering = onReordering
        self.onPlay = onPlay
    }
    
    var body: some View {
        PatchedGeometryReader { geometry in
            HStack {
                LazyImage(url: mediaTrack.artwork.getUrl(width: 50, height: 50)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                    }
                    
                    Color.clear
                }
                    .cornerRadius(5)
                    .brightness(isHovering ? -0.5 : 0)
                    .padding(.leading, 2)
                    .padding(.vertical, 2)
                    .overlay {
                        if isHovering {
                            Image(systemSymbol: .playFill)
                        }
                    }
                    .onTapGesture {
                        self.onPlay?()
                    }
                
                VStack(alignment: .leading) {
                    Text(mediaTrack.title)
                    ArtistNamesInteractiveText(item: .mediaTrack(mediaTrack))
                }
                
                Spacer()
            }
            .shadow(radius: isHovering ? 7 :.zero)
            .background(.thickMaterial.opacity(isClicking ? 1 : 0))
            .cornerRadius(5)
            .onHover { isHovering in
                self.isHovering = isHovering
            }
            .draggable(onDrag: { offset in
                // Determine draggable's current location on the list, adding 2 to make up for the additional padding, idek why this works i figured this out at midnight dont blame me
                let moveIndex = Int(round((offset.y / (geometry.size.height + 2)) / 4))
                self.onReordering?(moveIndex)
            }, allowDragging: $allowReordering)
            .modifier(PressActions(onEvent: { isClicking in
                if !isClicking {
                    self.onReordering?(nil)
                }
                
                withAnimation(.interactiveSpring()) {
                    self.isClicking = isClicking
                }
            }))
            .frame(height: geometry.size.height)
            .padding(.vertical, 2)
            .zIndex(isClicking ? 1 : 0)
        }
        .enableInjection()
    }
}

struct QueueTrackView_Previews: PreviewProvider {
    static var previews: some View {
        QueueTrackView(track: MediaTrack(data: []))
    }
}
