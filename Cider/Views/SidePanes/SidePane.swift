//
//  SidePane.swift
//  Cider
//
//  Created by Sherlock LUK on 01/04/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject

struct SidePane<HeaderChildren: View, Content: View>: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @ViewBuilder private let content: Content
    @ViewBuilder private let headerChildren: HeaderChildren
    private let title: String?
    private let direction: SidePaneDirection
    
    enum SidePaneDirection {
        case Left, Right
    }
    
    init(title: String? = nil, direction: SidePaneDirection = .Right, @ViewBuilder content: @escaping () -> Content, @ViewBuilder headerChildren: @escaping () -> HeaderChildren) {
        self.title = title
        self.direction = direction
        self.content = content()
        self.headerChildren = headerChildren()
    }
    
    var body: some View {
        PatchedGeometryReader { geometry in
            VStack {
                if let title = title {
                    HStack {
                        Text(title)
                            .font(.title.bold())
                        Spacer()
                        
                        headerChildren
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(maxHeight: geometry.size.height * 0.95)
            .frame(width: (geometry.maxRelative * 0.2).clamped(to: 275...320))
            .background(.ultraThinMaterial)
            .shadow(radius: 7)
            .cornerRadius(10)
        }
        .padding(direction == .Left ? .leading : .trailing, 10)
        .padding(.top, 7)
        .frame(maxWidth: .infinity, alignment: direction == .Left ? .leading : .trailing)
        .enableInjection()
    }
}

extension SidePane where HeaderChildren == EmptyView {
    
    init(title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.init(title: title, content: content, headerChildren: { EmptyView() })
    }
    
}

struct SidePane_Previews: PreviewProvider {
    static var previews: some View {
        SidePane(title: "SidePane") {
            EmptyView()
        }
    }
}
