//
//  TapEffectModifier.swift
//  Cider
//
//  Created by Sherlock LUK on 20/08/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftUI

struct TapEffectModifier: ViewModifier {
    
    @State private var isClicking = false
    
    func body(content: Content) -> some View {
        content
            .brightness(isClicking ? -0.2 : 0)
            .modifier(PressActions(onEvent: { isClicking in
                self.isClicking = isClicking
            }))
    }
    
}
