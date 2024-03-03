//
//  MediaTableRepresentable.swift
//  Cider
//
//  Created by Sherlock LUK on 16/07/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import NukeUI
import Inject

struct MediaItemRepresentable: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    @State private var isHovering: Bool = false
    @State private var isClicked: Bool = false
    
    private let item: MediaDynamic
    
    init(item: MediaDynamic) {
        self.item = item
    }
    
    var body: some View {
        HStack(alignment: .center) {
            LazyImage(url: item.artwork.getUrl(width: 40, height: 40))
                .frame(width: 30, height: 30)
                .cornerRadius(5, antialiased: true)
                .brightness(isHovering ? -0.5 : 0)
                .overlay(Image(systemSymbol: .playFill).opacity(isHovering ? 1 : 0))
            VStack(alignment: .leading) {
                HStack {
                    Text(item.title)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if item.contentRating == "explicit" {
                        Image(systemSymbol: .eSquareFill)
                    }
                }
                
                if !item.artistName.isEmpty {
                    ArtistNamesInteractiveText(item: item)
                }
            }
            Spacer()
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isHovering ? Color("SecondaryColour").opacity(isClicked ? 0.7 : 0.5) : Color.clear)
                .animation(.interactiveSpring(), value: isHovering || isClicked)
        )
        .onHover { isHovering in
            withAnimation(.easeIn.speed(10)) {
                self.isHovering = isHovering
            }
        }
        .onTapGesture {
            Task {
                await self.ciderPlayback.playbackEngine.setQueue(item: self.item)
                await self.ciderPlayback.clearAndPlay(shuffle: false)
            }
        }
        .modifier(PressActions(onEvent: { isPressed in
            self.isClicked = isPressed
        }))
        .modifier(CatalogActions(item: item))
        .enableInjection()
    }
    
}

struct MediaItemRepresentable_Previews: PreviewProvider {
    static var previews: some View {
        MediaItemRepresentable(item: .mediaTrack(MediaTrack(data: [])))
    }
}

struct MediaTableRepresentable: View {
    
    @ObservedObject private var iO = Inject.observer
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    private let items: [MediaDynamic]
    private let columnSpacing: CGFloat
    
    init(_ items: [MediaDynamic], columnSpacing: CGFloat = 300) {
        self.items = items
        self.columnSpacing = columnSpacing
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: columnSpacing))], alignment: .leading) {
            ForEach(items, id: \.id) { item in
                MediaItemRepresentable(item: item)
            }
        }
    }
    
}
