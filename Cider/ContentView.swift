//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                
            }
            .frame(minWidth: 480, minHeight: 360)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
