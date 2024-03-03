//
//  NavigationDebugger.swift
//  Cider
//
//  Created by Sherlock LUK on 27/02/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject

struct NavigationDebugger: View {
    
    @EnvironmentObject private var navigationModal: NavigationModal
    
    @ObservedObject private var observer = Inject.observer
    
    func getStackTypeName(stackParams: NavigationDynamicParams) -> String {
        if case .detailedViewParams = stackParams {
            return "DetailedView"
        }
        
        if case .artistViewParams = stackParams {
            return "ArtistView"
        }
        
        return "RootView"
    }
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Current Root Stack: \(String(describing: navigationModal.currentRootStack))")
                Text("Loaded Root Stacks: \(navigationModal.loadedRootStacks.map { String(describing: $0) }.joined(separator: ", "))")
                ForEach(navigationModal.viewsStack, id: \.id) { viewStack in
                    Text("""
ID: \(viewStack.id)
From Root Stack: \(String(describing: viewStack.rootStackOrigin ?? .AnyView))
Type: \(getStackTypeName(stackParams: viewStack.params ?? .rootViewParams))
Is Present: \(viewStack.isPresent ? "Present" : "Hidden")
""")
                    .padding()
                    .frame(minWidth: 370)
                    .background(.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                }
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 500)
        .enableInjection()
    }
}

#Preview {
    NavigationDebugger()
}
