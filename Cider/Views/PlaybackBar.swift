//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject

struct PlaybackBar: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @State private var geoSize = CGSize()
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(.red)
                .frame(width: geoSize.width, height: 5)
                .overlay {
                    GeometryReader { geometry in
                        Group {
                            
                        }
                        .onChange(of: geometry.size) { newSize in
                            self.geoSize = newSize
                        }
                        .onAppear {
                            self.geoSize = geometry.size
                        }
                    }
                }
        }
        .enableInjection()
    }
}

struct PlaybackBar_Previews: PreviewProvider {
    static var previews: some View {
        PlaybackBar()
    }
}
