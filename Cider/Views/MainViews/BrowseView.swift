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
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                Text("Browse")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                
                ForEach(browseData, id: \.id) { browseDataRow in
                    Text(browseDataRow.name)
                }
            }
        }
        .transparentScrollbars()
        .task {
            self.browseData = await self.mkModal.AM_API.fetchBrowse()
        }
        .enableInjection()
    }
}

struct BrowseView_Previews: PreviewProvider {
    static var previews: some View {
        BrowseView()
    }
}
