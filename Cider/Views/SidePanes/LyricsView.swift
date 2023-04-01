//
//  LyricsView.swift
//  Cider
//
//  Created by Sherlock LUK on 01/04/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import InjectHotReload

struct LyricsData {
    let id: String
    let lyricsTtml: String
}

struct LyricsView: View {
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    @ObservedObject private var iO = Inject.observer
    
    @State private var lyricsData: LyricsData?
    
    var body: some View {
        SidePane(title: "Lyrics", content: {
            GeometryReader { scrollGeometry in
                ScrollView(.vertical) {
                    VStack {
                        if let lyricsTtml = lyricsData?.lyricsTtml {
                            Text(lyricsTtml)
                        }
                    }
                    .frame(width: scrollGeometry.size.width)
                    
                    Spacer()
                        .frame(height: 50)
                }
            }
        })
        .task {
            if let item = self.ciderPlayback.nowPlayingState.item, let lyricsXml = await self.mkModal.AM_API.fetchLyricsXml(item: item), item.id != self.lyricsData?.id {
                self.lyricsData = LyricsData(id: item.id, lyricsTtml: lyricsXml)
            }
        }
        .enableInjection()
    }
}

struct LyricsView_Previews: PreviewProvider {
    static var previews: some View {
        LyricsView()
    }
}
