//
//  ArtistNamesInteractiveText.swift
//  Cider
//
//  Created by Sherlock LUK on 25/03/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject

struct ArtistNamesInteractiveText: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var mkModal: MKModal
    
    @State private var showArtistPicker = false
    @State var item: MediaDynamic
    
    var body: some View {
        InteractiveText("\(item.artistName)")
            .font(.system(.caption))
            .opacity(0.8)
            .onTapGesture {
                Task {
                    if let detailedMediaTrack = try? await self.mkModal.AM_API.fetchSong(id: self.item.id) {
                        withAnimation(.interactiveSpring()) {
                            self.item = .mediaTrack(detailedMediaTrack)
                            if detailedMediaTrack.artistsData.count > 1 {
                                self.showArtistPicker.toggle()
                            } else {
                                self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .artistViewParams(ArtistViewParams(originMediaItem: self.item))))
                            }
                        }
                    }
                }
            }
            .popover(isPresented: $showArtistPicker, attachmentAnchor: .point(.center), arrowEdge: .bottom) {
                VStack {
                    let artistNames = item.artistName.components(separatedBy: " & ")
                    ForEach(0..<artistNames.count, id: \.self) { index in
                        InteractiveText(artistNames[index])
                            .onTapGesture {
                                self.showArtistPicker = false
                                self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .artistViewParams(ArtistViewParams(originMediaItem: self.item, selectingArtistIndex: index))))
                            }
                    }
                }
                .padding()
            }
            .enableInjection()
    }
}

struct ArtistNamesInteractiveText_Previews: PreviewProvider {
    static var previews: some View {
        ArtistNamesInteractiveText(item: .mediaItem(MediaItem(data: [])))
    }
}
