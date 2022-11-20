//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload

struct InteractiveText: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @State private var title: String
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
    
    @ObservedObject private var iO = Inject.observer
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: "https://lastfm.freetls.fastly.net/i/u/770x0/f14944a5f6bb6a70a0d1256524da9fc2.jpg#f14944a5f6bb6a70a0d1256524da9fc2")) { image in
                image
                    .interpolation(.none)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 50, height: 50)
            .cornerRadius(5)
            
            VStack(alignment: .leading) {
                Text("Permission To Dance")
                    .font(.system(.headline))
                
                InteractiveText("BTS")
                InteractiveText("Butter")
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
