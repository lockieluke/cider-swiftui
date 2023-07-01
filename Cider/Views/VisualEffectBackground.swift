//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif
import SwiftUI

struct VisualEffectBackground: ViewRepresentable {
    
    #if canImport(AppKit)
    private let material: NSVisualEffectView.Material
    
    init(material: NSVisualEffectView.Material = .windowBackground) {
        self.material = material
    }
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        return NSVisualEffectView()
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
    #elseif canImport(UIKit)
    private let effect: UIVisualEffect
    
    init(effect: UIVisualEffect = UIBlurEffect(style: .systemMaterial)) {
        self.effect = effect
    }
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView()
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
    
    #endif
}
