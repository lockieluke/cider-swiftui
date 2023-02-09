//
//  MediaArtistPresentable.swift
//  Cider
//
//  Created by Sherlock LUK on 08/02/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct MediaArtistPresentable: View {
    
    @EnvironmentObject private var navigationModal: NavigationModal
    
    var artist: MediaArtist
    var maxRelative: CGFloat
    
    @State private var isHovering = false
    
    var body: some View {
        VStack {
            WebImage(url: self.artist.artwork.getUrl(width: 200, height: 200))
                .resizable()
                .placeholder {
                    ProgressView()
                }
                .scaledToFit()
                .frame(width: maxRelative * 0.15, height: maxRelative * 0.15)
                .cornerRadius(.infinity)
                .brightness(isHovering ? -0.2 : 0)
                .animation(.easeIn(duration: 0.15), value: isHovering)
                .onHover { isHovering in
                    self.isHovering = isHovering
                }
                .onTapGesture {
                    withAnimation(.interactiveSpring()) {
                        self.navigationModal.appendViewStack(NavigationStack(stackType: .Artist, isPresent: true, params: ArtistViewParams(artist: self.artist)))
                    }
                }
            
            Text(artist.artistName)
        }
    }
}

struct MediaArtistPresentable_Previews: PreviewProvider {
    static var previews: some View {
        MediaArtistPresentable(artist: MediaArtist(data: []), maxRelative: .zero)
    }
}
