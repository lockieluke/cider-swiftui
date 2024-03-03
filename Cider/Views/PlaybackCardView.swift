//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject
import SFSafeSymbols
import NukeUI
import Nuke

struct PlaybackCardView: View {
    
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var navigationModal: NavigationModal
    
    @ObservedObject private var iO = Inject.observer
    
    var body: some View {
        HStack {
            let nowPlayingState = ciderPlayback.nowPlayingState
            
            LazyImage(url: nowPlayingState.artworkURL ?? Bundle.main.url(forResource: "MissingArtwork", withExtension: ".png")!) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .frame(width: 50, height: 50)
                }
                
                Color.clear
            }
                .pipeline(ImagePipeline(configuration: .withURLCache))
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            
            VStack(alignment: .leading) {
                HStack(spacing: 0) {
                    Text(nowPlayingState.name ?? "Not Playing")
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.system(.headline))
                    
                    if nowPlayingState.contentRating == "explicit" {
                        Image(systemSymbol: .eSquareFill)
                            .padding(.horizontal, 2)
                    }
                }
                
                InteractiveText(nowPlayingState.artistName ?? "")
                    .onTapGesture {
                        withAnimation(.interactiveSpring()) {
                            if let item = self.ciderPlayback.nowPlayingState.item {
                                self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .artistViewParams(ArtistViewParams(originMediaItem: item))))
                            }
                        }
                    }
                InteractiveText("")
                    .foregroundColor(.gray)
            }
            .padding([.horizontal, .vertical], 10)
        }
        .if(!ciderPlayback.nowPlayingState.item.isNil) { view in
            view
                .modifier(CatalogActions(item: ciderPlayback.nowPlayingState.item!, isNowPlaying: true))
        }
        .enableInjection()
    }
}

struct PlaybackCardView_Previews: PreviewProvider {
    static var previews: some View {
        PlaybackCardView()
    }
}
