//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftUI
import SwiftUIIntrospect

struct TransparentScrollbarsModifier: ViewModifier {
    
    var enabled: Bool
    
    func body(content: Content) -> some View {
        #if canImport(AppKit)
        content
            .introspect(.scrollView, on: .macOS(.v10_15, .v11, .v12, .v13, .v14)) { scrollView in
                scrollView.autohidesScrollers = true
                scrollView.scrollerStyle = .overlay
            }
        #else
        return content
        #endif
    }
    
}
