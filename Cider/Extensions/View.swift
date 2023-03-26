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
         MousePrimaryReleased,
         MouseSecondaryPressed,
         MouseSecondaryReleased
    
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
            }
            
            override func mouseUp(with event: NSEvent) {
                mouseEventCB?(.MousePrimaryReleased)
            }
            
            override func rightMouseDown(with event: NSEvent) {
                mouseEventCB?(.MouseSecondaryPressed)
            }
            
            override func rightMouseUp(with event: NSEvent) {
                mouseEventCB?(.MouseSecondaryReleased)
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

/// An animatable modifier that is used for observing animations for a given animatable value.
struct AnimationCompletionObserverModifier<Value>: AnimatableModifier where Value: VectorArithmetic {
    
    /// While animating, SwiftUI changes the old input value to the new target value using this property. This value is set to the old value until the animation completes.
    var animatableData: Value {
        didSet {
            notifyCompletionIfFinished()
        }
    }
    
    /// The target value for which we're observing. This value is directly set once the animation starts. During animation, `animatableData` will hold the oldValue and is only updated to the target value once the animation completes.
    private var targetValue: Value
    
    /// The completion callback which is called once the animation completes.
    private var completion: () -> Void
    
    init(observedValue: Value, completion: @escaping () -> Void) {
        self.completion = completion
        self.animatableData = observedValue
        targetValue = observedValue
    }
    
    /// Verifies whether the current animation is finished and calls the completion callback if true.
    private func notifyCompletionIfFinished() {
        guard animatableData == targetValue else { return }
        
        /// Dispatching is needed to take the next runloop for the completion callback.
        /// This prevents errors like "Modifying state during view update, this will cause undefined behavior."
        DispatchQueue.main.async {
            self.completion()
        }
    }
    
    func body(content: Content) -> some View {
        /// We're not really modifying the view so we can directly return the original input value.
        return content
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
        self.frame(maxWidth: hidden ? .zero : .infinity, maxHeight: hidden ? .zero : .infinity)
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
    
    func contextMenu(_ contextMenuArgs: [ContextMenuArg] = [], onAppear: (() -> Void)? = nil, _ onAction: ((_ id: String) -> Void)? = nil) -> some View {
        modifier(ContextMenu(contextMenuArgs, onAppear: onAppear, onAction))
    }
    
    func erasedToAnyView() -> AnyView {
        AnyView(self)
    }
    
    @ViewBuilder func isHidden(_ hidden: Bool, remove: Bool = false) -> some View {
        if hidden {
            if !remove {
                self.hidden()
            }
        } else {
            self
        }
    }
    
    func tooltip(_ toolTip: String) -> some View {
        if #available(macOS 13.0, *) {
            return self.help(toolTip)
        } else {
            return self.overlay(TooltipView(tooltip: toolTip))
        }
    }
    
    func multicolourGlow(gradientColours: Gradient = Gradient(colors: [])) -> some View {
        return self.modifier(MultiColourGlow(gradientColours: gradientColours))
    }
    
    func disableScrolling(disabled: Bool) -> some View {
        modifier(DisableScrollingModifier(scrollingDisabled: disabled))
    }
    
    func transparentScrollbars(_ enabled: Bool = true) -> some View {
        self.modifier(TransparentScrollbarsModifier(enabled: enabled))
    }
    
    func onAnimationCompleted<Value: VectorArithmetic>(for value: Value, completion: @escaping () -> Void) -> ModifiedContent<Self, AnimationCompletionObserverModifier<Value>> {
        return modifier(AnimationCompletionObserverModifier(observedValue: value, completion: completion))
    }
    
    func draggable() -> some View {
        return modifier(DraggableView())
    }
    
}

struct PressActions: ViewModifier {
    
    var onEvent: ((_ isPressed: Bool) -> Void)?
    var onPress: (() -> Void)?
    var onRelease: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in
                        onPress?()
                        onEvent?(true)
                    })
                    .onEnded({ _ in
                        onRelease?()
                        onEvent?(false)
                    })
            )
    }
}
