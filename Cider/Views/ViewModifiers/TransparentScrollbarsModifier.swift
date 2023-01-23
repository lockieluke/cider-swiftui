//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftUI

struct TransparentScrollbarsModifier: ViewModifier {
    
    var enabled: Bool
    
    func body(content: Content) -> some View {
        content
            .introspectScrollView { scrollView in
                scrollView.autohidesScrollers = true
                scrollView.scrollerStyle = .overlay
            }
    }
    
}
