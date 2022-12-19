//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftUI

struct TooltipView: NSViewRepresentable {
    
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
