//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
#if canImport(AppKit)
import AppKit
#endif
import SwiftUI

struct TooltipView: ViewRepresentable {
    
    let tooltip: String
    
    func makeNSView(context: NSViewRepresentableContext<TooltipView>) -> NSView {
        let view = NSView()
        view.toolTip = tooltip
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<TooltipView>) {
        nsView.toolTip = tooltip
    }
    
}
