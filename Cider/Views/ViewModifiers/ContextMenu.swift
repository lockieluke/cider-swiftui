//
//  ContextMenu.swift
//  Cider
//
//  Created by Sherlock LUK on 01/03/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject

struct ContextMenuArg {
    
    let title: String?
    let id: String
    let type: ContextMenuArgType
    let disabled: Bool
    let visible: Bool
    
    enum ContextMenuArgType {
        case separator, general
    }
    
    init(_ title: String, id: String? = nil, disabled: Bool = false, visible: Bool = true) {
        self.title = title
        self.id = id ?? title.lowerKebabCased()
        self.type = .general
        self.disabled = disabled
        self.visible = visible
    }
    
    init(type: ContextMenuArgType = .separator) {
        self.title = nil
        self.id = UUID().uuidString
        self.type = type
        self.disabled = false
        self.visible = true
    }
}

struct ContextMenu: ViewModifier {
    
    private let args: [ContextMenuArg]
    private let onAppear: (() -> Void)?
    private let onAction: ((_ id: String) -> Void)?
    
    init(_ args: [ContextMenuArg] = [], onAppear: (() -> Void)? = nil, _ onAction: ((_ id: String) -> Void)? = nil) {
        self.args = args
        self.onAppear = onAppear
        self.onAction = onAction
    }
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                ForEach(args.filter { $0.visible }, id: \.id) { arg in
                    if let title = arg.title  {
                        Button(action: {
                            self.onAction?(arg.id)
                        }, label: {
                            Text(title)
                        })
                        .disabled(arg.disabled)
                    } else if arg.type == .separator {
                        Divider()
                    }
                }
                .onAppear {
                    self.onAppear?()
                }
            }
    }
    
}
