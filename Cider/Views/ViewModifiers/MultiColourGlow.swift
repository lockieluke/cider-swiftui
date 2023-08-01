//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftUI

struct MultiColourGlow: ViewModifier {
    
    let gradientColours: Gradient
    
    func body(content: Content) -> some View {
        ZStack {
            ForEach(0..<2) { i in
                Rectangle()
                    .fill(AngularGradient(gradient: self.gradientColours, center: .center))
                    .mask(content.blur(radius: 10))
                    .overlay(content.blur(radius: 5 - (i * 10).f))
            }
        }
    }
    
}
