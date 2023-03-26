//
//  QueueItemView.swift
//  Cider
//
//  Created by Sherlock LUK on 24/03/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import InjectHotReload

struct QueueTrackView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @State private var isHovering = false
    @State private var isClicking = false
    
    private let mediaTrack: MediaTrack
    
    init(track: MediaTrack) {
        self.mediaTrack = track
    }
    
    var body: some View {
        HStack {
            WebImage(url: mediaTrack.artwork.getUrl(width: 50, height: 50))
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .cornerRadius(5)
                .padding(.leading, 2)
                .padding(.vertical, 2)
            
            VStack(alignment: .leading) {
                Text(mediaTrack.title)
                ArtistNamesInteractiveText(item: .mediaTrack(mediaTrack))
            }
            
            Spacer()
        }
        .background(.thinMaterial.opacity(isHovering ? (isClicking ? 0.7 : 1) : 0))
        .cornerRadius(5)
        .onHover { isHovering in
            self.isHovering = isHovering
        }
        .modifier(PressActions(onEvent: { isClicking in
            self.isClicking = isClicking
        }))
        .padding(.vertical, 2)
        .enableInjection()
    }
}

struct QueueTrackView_Previews: PreviewProvider {
    static var previews: some View {
        QueueTrackView(track: MediaTrack(data: []))
    }
}
