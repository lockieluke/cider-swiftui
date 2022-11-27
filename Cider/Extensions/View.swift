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

enum MouseEvent {
    
    case MouseEntered,
    MouseLeft,
    MousePrimaryPressed,
    MousePrimaryReleased
    
}

struct MouseModifier: ViewModifier {
    
    let mouseEventCB: (MouseEvent) -> Void
    
    init(_ mouseEventCB: @escaping (MouseEvent) -> Void) {
        self.mouseEventCB = mouseEventCB
    }
    
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                Representable(mouseEventCB: self.mouseEventCB, frame: proxy.frame(in: .global))
            }
        )
    }
    
    private struct Representable: NSViewRepresentable {
        
        let mouseEventCB: (MouseEvent) -> Void
        let frame: NSRect
        
        func makeCoordinator() -> Coordinator {
            let coordinator = Coordinator()
            coordinator.mouseEventCB = mouseEventCB
            return coordinator
        }
        
        class Coordinator: NSResponder {
            var mouseEventCB: ((MouseEvent) -> Void)?
            
            override func mouseEntered(with event: NSEvent) {
                mouseEventCB?(.MouseEntered)
            }
            
            override func mouseExited(with event: NSEvent) {
                mouseEventCB?(.MouseLeft)
            }
            
            override func mouseDown(with event: NSEvent) {
                mouseEventCB?(.MousePrimaryPressed)
                super.mouseDown(with: event)
                mouseEventCB?(.MousePrimaryReleased)
            }
            
            override func mouseDragged(with event: NSEvent) {
                print("dragged")
            }
            
        }
        
        func makeNSView(context: Context) -> NSView {
            let view = NSView(frame: frame)
            
            let options: NSTrackingArea.Options = [
                .mouseEnteredAndExited,
                .inVisibleRect,
                .activeInKeyWindow
            ]
            
            let trackingArea = NSTrackingArea(rect: frame,
                                              options: options,
                                              owner: context.coordinator,
                                              userInfo: nil)
            
            view.addTrackingArea(trackingArea)
            
            return view
        }
        
        func updateNSView(_ nsView: NSView, context: Context) {}
        
        static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
            nsView.trackingAreas.forEach { nsView.removeTrackingArea($0) }
        }
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
    
    func captureMouseEvents(_ mouseEventCB: @escaping (MouseEvent) -> Void) -> some View {
        modifier(MouseModifier(mouseEventCB))
    }
    
    func captureMouseEvent(_ mouseEvent: MouseEvent, _ mouseEventCB: @escaping () -> Void) -> some View {
        modifier(MouseModifier({ thisMouseEvent in
            if thisMouseEvent == mouseEvent {
                mouseEventCB()
            }
        }))
    }
    
    func erasedToAnyView() -> AnyView {
        AnyView(self)
    }
    
}

struct PressActions: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in
                        onPress()
                    })
                    .onEnded({ _ in
                        onRelease()
                    })
            )
    }
    
}
