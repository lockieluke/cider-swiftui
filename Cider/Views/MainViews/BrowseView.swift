//
//  BrowseView.swift
//  Cider
//
//  Created by Sherlock LUK on 28/07/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject

struct BrowseView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    
    @State private var browseData: [MediaBrowseData] = []
    @State private var browseData316: [MediaBrowseData] = []
    
    @Namespace private var animationNamespace
    
    let heroCardSize: CGSize = CGSize(width: 550, height: 225)
    let coverKindValue: String = "bb"
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                Text("Browse")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(browseData316, id: \.id) { browseDataRow in
                            ForEach(browseDataRow.items, id: \.self) { item in
                                HeroCard(
                                    item: item,
                                    geometryMatching: animationNamespace,
                                    originalSize: heroCardSize,
                                    coverKind: coverKindValue
                                )
                                .frame(width: heroCardSize.width, height: heroCardSize.height)
                            }
                        }
                    }
                }
                
                
                
            }
        }
        .task {
            self.browseData = await self.mkModal.AM_API.fetchBrowse()
            self.browseData316 = browseData.filter { $0.kind.rawValue == "316" }
        }
        .enableInjection()
    }
}

struct BrowseView_Previews: PreviewProvider {
    static var previews: some View {
        BrowseView()
    }
}
