//
//  RecentlyAddedView.swift
//  Cider
//
//  Created by Sherlock LUK on 27/02/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject
import Lottie

struct RecentlyAddedView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    
    @State private var recentlyAddedItems: [MediaDynamic] = []
    @State private var isFetching: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Recently Added")
                    .bold()
                    .font(.title2)
                
                Spacer()
                
                if isFetching {
                    LottieView(animation: try! .from(data: precompileIncludeData("@/Cider/Resources/CiderSpinner.json")))
                        .playing(loopMode: .loop)
                        .clipShape(Rectangle())
                        .frame(width: 15, height: 15)
                }
            }
            .padding(.horizontal, 15)
            
            ScrollView {
                PatchedGeometryReader { geometry in
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], alignment: .center, spacing: 50) {
                        ForEach(recentlyAddedItems, id: \.id) { item in
                            MediaPresentable(item: item, maxRelative: geometry.maxRelative.clamped(to: 1000...1100))
                                .task {
                                    if recentlyAddedItems.last?.id == item.id {
                                        self.isFetching = true
                                        let newItems = await self.mkModal.AM_API.fetchRecentlyAdded(offset: recentlyAddedItems.count)
                                        self.recentlyAddedItems.append(contentsOf: newItems)
                                        self.isFetching = false
                                    }
                                }
                        }
                    }
                    
                    Spacer()
                        .frame(height: 20)
                }
            }
            .transparentScrollbars()
        }
        .task {
            self.isFetching = true
            self.recentlyAddedItems = await self.mkModal.AM_API.fetchRecentlyAdded()
            self.isFetching = false
        }
        .enableInjection()
    }
}

#Preview {
    RecentlyAddedView()
}
