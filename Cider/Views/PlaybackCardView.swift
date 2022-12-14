//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload
import SDWebImageSwiftUI

struct InteractiveText: View {
    
    @ObservedObject private var iO = Inject.observer
    
    var title: String
    @State private var isHovered: Bool = false
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        Text(title)
            .background(RoundedRectangle(cornerRadius: 2).fill(isHovered ? Color("SecondaryColour") : .clear))
            .onHover { isHovered in
                self.isHovered = isHovered
            }
            .enableInjection()
    }
    
}

struct PlaybackCardView: View {
    
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    @ObservedObject private var iO = Inject.observer
    
    var body: some View {
        HStack {
            let nowPlayingState = ciderPlayback.nowPlayingState
            
            Group {
                if let artworkURL = nowPlayingState.artworkURL {
                    WebImage(url: artworkURL)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .cornerRadius(5)
                } else {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.secondary)
                }
            }
            .frame(width: 50, height: 50)
            
            VStack(alignment: .leading) {
                Text(nowPlayingState.name ?? "Not Playing")
                    .font(.system(.headline))
                
                InteractiveText(nowPlayingState.artistName ?? "")
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
