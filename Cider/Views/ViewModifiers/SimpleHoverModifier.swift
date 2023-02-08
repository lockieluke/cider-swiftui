//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftUI

struct SimpleHoverModifier: ViewModifier {
    
    @State private var isHovering = false
    
    func body(content: Content) -> some View {
        content
            .brightness(isHovering ? -0.1 : 0)
            .onHover { isHovering in
                withAnimation(.easeIn(duration: 0.15)) {
                    self.isHovering = isHovering
                }
            }
    }
    
}
