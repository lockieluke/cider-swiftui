//
//  DraggableView.swift
//  Cider
//
//  Created by Sherlock LUK on 26/03/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftUI
import Throttler

struct DraggableView: ViewModifier {
    
    @State private var offset = CGPoint(x: 0, y: 0)
    
    func body(content: Content) -> some View {
        content
            .gesture(DragGesture(coordinateSpace: .global)
                .onChanged { value in
                    self.offset.x = value.location.x - value.startLocation.x
                    self.offset.y = value.location.y - value.startLocation.y
                }
                .onEnded { value in
                    withAnimation(.interactiveSpring()) {
                        self.offset = .zero
                    }
                }
            )
            .offset(x: offset.x, y: offset.y)
    }
    
}
