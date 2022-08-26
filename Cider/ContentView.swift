//
//  ContentView.swift
//  Cider
//
//  Created by Sherlock LUK on 26/08/2022.
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
