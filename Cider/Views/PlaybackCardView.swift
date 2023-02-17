//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload
import SDWebImageSwiftUI

struct PlaybackCardView: View {
    
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var navigationModal: NavigationModal
    
    @ObservedObject private var iO = Inject.observer
    
    var body: some View {
        HStack {
            let nowPlayingState = ciderPlayback.nowPlayingState
            
            WebImage(url: nowPlayingState.artworkURL ?? Bundle.main.url(forResource: "MissingArtwork", withExtension: ".png")!)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .cornerRadius(5)
            
            VStack(alignment: .leading) {
                Text(nowPlayingState.name ?? "Not Playing")
                    .font(.system(.headline))
                
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
        .padding()
        .enableInjection()
    }
}

struct PlaybackCardView_Previews: PreviewProvider {
    static var previews: some View {
        PlaybackCardView()
    }
}
