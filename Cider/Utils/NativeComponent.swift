//
//  Component.swift
//  Cider
//
//  Created by Sherlock LUK on 23/08/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI

public struct NativeComponent<Target, Coordinator, Body: View>: View {
    private var makeBody: () -> Body
    public var body: Body { makeBody() }
}

#if os(macOS)
public struct _ViewBody<Target: NSView, Coordinator>: NSViewRepresentable {
    internal var _makeTarget: (Context) -> Target
    internal var _updateTarget: (Target, Context) -> Void
    internal var _makeCoordinator: () -> Coordinator
    public func makeNSView(context: Context) -> Target {
        _makeTarget(context)
    }
    public func updateNSView(_ nsView: Target, context: Context) {
        _updateTarget(nsView, context)
    }
    public func makeCoordinator() -> Coordinator {
        _makeCoordinator()
    }
}

public struct _ViewControllerBody<Target: NSViewController, Coordinator>: NSViewControllerRepresentable {
    internal var _makeTarget: (Context) -> Target
    internal var _updateTarget: (Target, Context) -> Void
    internal var _makeCoordinator: () -> Coordinator
    public func makeNSViewController(context: Context) -> Target {
        _makeTarget(context)
    }
    public func updateNSViewController(_ nsViewController: Target, context: Context) {
        _updateTarget(nsViewController, context)
    }
    public func makeCoordinator() -> Coordinator {
        _makeCoordinator()
    }
}

extension NativeComponent
where Target: NSView, Body == _ViewBody<Target, Coordinator> {
    public init(target: @escaping (Body.Context) -> Target,
                coorinator: @escaping () -> Coordinator,
                onUpdate:((Target, Body.Context) -> Void)? = .none) {
        makeBody = {
            Body(
                _makeTarget: target,
                _updateTarget: onUpdate ?? { _, _ in },
                _makeCoordinator: coorinator
            )
        }
    }
    
    public init(target: @escaping () -> Target,
                coorinator: @escaping () -> Coordinator,
                onUpdate: ((Target, Body.Context) -> Void)? = .none) {
        self.init(
            target: { _ in target() },
            coorinator: coorinator,
            onUpdate: onUpdate
        )
    }
    
    public init(target: @escaping () -> Target,
                coorinator: @escaping @autoclosure () -> Coordinator,
                onUpdate: ((Target, Body.Context) -> Void)? = .none) {
        self.init(
            target: target,
            coorinator: coorinator,
            onUpdate: onUpdate
        )
    }
    
    public init(_ target: @escaping @autoclosure () -> Target,
                coorinator: @escaping () -> Coordinator,
                onUpdate: ((Target, Body.Context) -> Void)? = .none) {
        self.init(
            target: target,
            coorinator: coorinator,
            onUpdate: onUpdate
        )
    }
    
    public init(_ target: @escaping @autoclosure () -> Target,
                coorinator: @escaping @autoclosure () -> Coordinator,
                onUpdate: ((Target, Body.Context) -> Void)? = .none) {
        self.init(
            target: target,
            coorinator: coorinator,
            onUpdate: onUpdate
        )
    }
}

extension NativeComponent
where Target: NSView, Coordinator == Void, Body == _ViewBody<Target, Coordinator> {
    public init(target: @escaping (Body.Context) -> Target,
                onUpdate:((Target, Body.Context) -> Void)? = .none) {
        makeBody = {
            Body(
                _makeTarget: target,
                _updateTarget: onUpdate ?? { _, _ in },
                _makeCoordinator: { () }
            )
        }
    }
    
    public init(target: @escaping () -> Target,
                onUpdate: ((Target, Body.Context) -> Void)? = .none) {
        self.init(
            target: { _ in target() },
            onUpdate: onUpdate
        )
    }
    
    public init(_ target: @escaping @autoclosure () -> Target,
                onUpdate: ((Target, Body.Context) -> Void)? = .none) {
        self.init(
            target: target,
            onUpdate: onUpdate
        )
    }
}

extension NativeComponent
where Target: NSViewController, Body == _ViewControllerBody<Target, Coordinator> {
    public init(target: @escaping (Body.Context) -> Target,
                coorinator: @escaping () -> Coordinator,
                onUpdate:((Target, Body.Context) -> Void)? = .none) {
        makeBody = {
            Body(
                _makeTarget: target,
                _updateTarget: onUpdate ?? { _, _ in },
                _makeCoordinator: coorinator
            )
        }
    }
    
    public init(_ target: @escaping @autoclosure () -> Target,
                coorinator: @escaping @autoclosure () -> Coordinator,
                onUpdate: ((Target, Body.Context) -> Void)? = .none) {
        makeBody = {
            Body(
                _makeTarget: { _ in target() },
                _updateTarget: onUpdate ?? { _, _ in },
                _makeCoordinator: coorinator
            )
        }
    }
}

extension NativeComponent
where Target: NSViewController, Coordinator == Void, Body == _ViewControllerBody<Target, Coordinator> {
    public init(target: @escaping (Body.Context) -> Target,
                onUpdate: ((Target, Body.Context) -> Void)? = .none) {
        makeBody = {
            Body(
                _makeTarget: target,
                _updateTarget: onUpdate ?? { _, _ in },
                _makeCoordinator: { () }
            )
        }
    }
    
    public init(_ target: @escaping @autoclosure () -> Target,
                onUpdate: ((Target, Body.Context) -> Void)? = .none) {
        makeBody = {
            Body(
                _makeTarget: { _ in target() },
                _updateTarget: onUpdate ?? { _, _ in },
                _makeCoordinator: { () }
            )
        }
    }
}

#elseif os(iOS)
public struct _ViewBody<Target: UIView, Coordinator>: UIViewRepresentable {
    internal var _makeTarget: (Context) -> Target
    internal var _updateTarget: (Target, Context) -> Void
    internal var _makeCoordinator: () -> Coordinator
    public func makeUIView(context: Context) -> Target {
        _makeTarget(context)
    }
    public func updateUIView(_ uiView: Target, context: Context) {
        _updateTarget(uiView, context)
    }
    public func makeCoordinator() -> Coordinator {
        _makeCoordinator()
    }
}

public struct _ViewControllerBody<Target: UIViewController, Coordinator>: UIViewControllerRepresentable {
    internal var _makeTarget: (Context) -> Target
    internal var _updateTarget: (Target, Context) -> Void
    internal var _makeCoordinator: () -> Coordinator
    public func makeUIViewController(context: Context) -> Target {
        _makeTarget(context)
    }
    public func updateUIViewController(_ uiViewController: Target, context: Context) {
        _updateTarget(uiViewController, context)
    }
    public func makeCoordinator() -> Coordinator {
        _makeCoordinator()
    }
}

extension NativeComponent
where Target: UIView, Body == _ViewBody<Target, Coordinator> {
    public init(target: @escaping (Body.Context) -> Target,
                coorinator: @escaping () -> Coordinator,
                onUpdate:((Target, Body.Context) -> Void)? = .none) {
        makeBody = {
            Body(
                _makeTarget: target,
                _updateTarget: onUpdate ?? { _, _ in },
                _makeCoordinator: coorinator
            )
        }
    }
    
    public init(_ target: @escaping @autoclosure () -> Target,
                coorinator: @escaping @autoclosure () -> Coordinator,
                onUpdate: ((Target, Body.Context) -> Void)? = .none) {
        makeBody = {
            Body(
                _makeTarget: { _ in target() },
                _updateTarget: onUpdate ?? { _, _ in },
                _makeCoordinator: coorinator
            )
        }
    }
}

extension NativeComponent
where Target: UIView, Coordinator == Void, Body == _ViewBody<Target, Coordinator> {
    public init(target: @escaping (Body.Context) -> Target,
                onUpdate: ((Target, Body.Context) -> Void)? = .none) {
        makeBody = {
            Body(
                _makeTarget: target,
                _updateTarget: onUpdate ?? { _, _ in },
                _makeCoordinator: { () }
            )
        }
    }
    
    public init(_ target: @escaping @autoclosure () -> Target,
                onUpdate: ((Target, Body.Context) -> Void)? = .none) {
        makeBody = {
            Body(
                _makeTarget: { _ in target() },
                _updateTarget: onUpdate ?? { _, _ in },
                _makeCoordinator: { () }
            )
        }
    }
}

extension NativeComponent
where Target: UIViewController, Body == _ViewControllerBody<Target, Coordinator> {
    public init(target: @escaping (Body.Context) -> Target,
                coorinator: @escaping () -> Coordinator,
                onUpdate:((Target, Body.Context) -> Void)? = .none) {
        makeBody = {
            Body(
                _makeTarget: target,
                _updateTarget: onUpdate ?? { _, _ in },
                _makeCoordinator: coorinator
            )
        }
    }
    
    public init(_ target: @escaping @autoclosure () -> Target,
                coorinator: @escaping @autoclosure () -> Coordinator,
                onUpdate: ((Target, Body.Context) -> Void)? = .none) {
        makeBody = {
            Body(
                _makeTarget: { _ in target() },
                _updateTarget: onUpdate ?? { _, _ in },
                _makeCoordinator: coorinator
            )
        }
    }
}

extension NativeComponent
where Target: UIViewController, Coordinator == Void, Body == _ViewControllerBody<Target, Coordinator> {
    public init(target: @escaping (Body.Context) -> Target,
                onUpdate: ((Target, Body.Context) -> Void)? = .none) {
        makeBody = {
            Body(
                _makeTarget: target,
                _updateTarget: onUpdate ?? { _, _ in },
                _makeCoordinator: { () }
            )
        }
    }
    
    public init(_ target: @escaping @autoclosure () -> Target,
                onUpdate: ((Target, Body.Context) -> Void)? = .none) {
        makeBody = {
            Body(
                _makeTarget: { _ in target() },
                _updateTarget: onUpdate ?? { _, _ in },
                _makeCoordinator: { () }
            )
        }
    }
}
#endif
