//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftUI

struct DisableScrollingModifier: ViewModifier {
    
    var scrollingDisabled: Bool
    
    func body(content: Content) -> some View {
        
        if scrollingDisabled {
            content
                .simultaneousGesture(DragGesture(minimumDistance: 0))
        } else {
            content
        }
        
    }
}
