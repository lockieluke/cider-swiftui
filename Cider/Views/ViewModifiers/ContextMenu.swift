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
    let isDev: Bool
    
    enum ContextMenuArgType {
        case separator, general
    }
    
    init(_ title: String, id: String? = nil, isDev: Bool = false) {
        self.title = title
        self.id = id ?? title.lowerKebabCased()
        self.type = .general
        self.isDev = isDev
    }
    
    init(type: ContextMenuArgType = .separator) {
        self.title = nil
        self.id = UUID().uuidString
        self.type = type
        self.isDev = false
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
                ForEach(args, id: \.id) { arg in
                    if arg.isDev == Diagnostic.isDebug {
                        if let title = arg.title {
                            Button {
                                self.onAction?(arg.id)
                            } label: {
                                Text(title)
                            }
                        } else if arg.type == .separator {
                            Divider()
                        }
                    }
                }
                .onAppear {
                    self.onAppear?()
                }
            }
    }
    
}
