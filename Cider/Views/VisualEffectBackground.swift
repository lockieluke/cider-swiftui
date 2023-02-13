//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import AppKit
import SwiftUI

struct VisualEffectBackground: NSViewRepresentable {
    
    private let material: NSVisualEffectView.Material
    
    init(material: NSVisualEffectView.Material = .windowBackground) {
        self.material = material
    }
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = self.material
        return visualEffectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // Nothing to do.
    }
}
