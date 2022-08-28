//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject

struct PlaybackView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    var body: some View {
        Group {
            HStack {
                PlaybackCardView()
                Spacer()
            }
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(Color("PrimaryColour"))
        .enableInjection()
    }
}

struct PlaybackView_Previews: PreviewProvider {
    static var previews: some View {
        PlaybackView()
    }
}
