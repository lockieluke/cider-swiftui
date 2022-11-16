//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftUI

struct AnimatableCustomFontModifier: ViewModifier, Animatable {
    var name: String
    var size: Double
    
    var animatableData: Double {
        get { size }
        set { size = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .font(.custom(name, size: size))
    }
}

struct AnimatableSystemFontModifier: ViewModifier, Animatable {
    var size: Double
    var weight: Font.Weight
    var design: Font.Design
    
    var animatableData: Double {
        get { size }
        set { size = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight, design: design))
    }
    
}

// To make that easier to use, I recommend wrapping
// it in a `View` extension, like this:
extension View {
    
    func animatableFont(name: String, size: Double) -> some View {
        self.modifier(AnimatableCustomFontModifier(name: name, size: size))
    }
    
    func animatableSystemFont(size: Double, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        self.modifier(AnimatableSystemFontModifier(size: size, weight: weight, design: design))
    }
    
    @ViewBuilder func hideWithoutDestroying(_ hidden: Bool) -> some View {
        if hidden {
            self.frame(width: .zero, height: .zero)
        } else {
            self
        }
    }
    
    func erasedToAnyView() -> AnyView {
        AnyView(self)
    }
}
