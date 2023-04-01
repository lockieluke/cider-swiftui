//
//  LyricsView.swift
//  Cider
//
//  Created by Sherlock LUK on 01/04/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import InjectHotReload
import SwiftyJSON
import WrappingHStack

struct LyricsLine {
    let id: String
    let line: String
    let start_time: Float
    let end_time: Float
}

struct LyricsData {
    let id: String
    let lyrics: [LyricsLine]
    let leadingSilence: Float
    let songwriters: [String]
}

struct LyricsView: View {
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var nativeUtilsWrapper: NativeUtilsWrapper
    
    @ObservedObject private var iO = Inject.observer
    
    @State private var lyricsData: LyricsData?
    @State private var lastSyncedId: String?
    
    var body: some View {
        SidePane(content: {
            GeometryReader { scrollGeometry in
                ScrollView(.vertical) {
                    VStack {
                        if let lyricsData = lyricsData {
                            WrappingHStack(["Songwriters: "] + lyricsData.songwriters, id: \.self) { songwriter in
                                Text(songwriter)
                                    .italic()
                            }
                            .padding()
                            
                            ForEach(lyricsData.lyrics, id: \.id) { lyric in
                                Text(lyric.line)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .frame(width: scrollGeometry.size.width)
                    
                    Spacer()
                        .frame(height: 50)
                }
            }
        })
        .task {
            if let item = self.ciderPlayback.nowPlayingState.item, item.id != self.lyricsData?.id, let lyricsXml = await self.mkModal.AM_API.fetchLyricsXml(item: item) {
                let lyricsJson = JSON(parseJSON: self.nativeUtilsWrapper.nativeUtils.parse_lyrics_xml(lyricsXml).toString())
                self.lyricsData = LyricsData(id: item.id, lyrics: lyricsJson["lyrics"].arrayValue.compactMap { line in
                    return LyricsLine(id: line["id"].stringValue, line: line["line"].stringValue, start_time: line["start_time"].floatValue, end_time: line["end_time"].floatValue)
                }, leadingSilence: lyricsJson["leadingSilence"].floatValue, songwriters: lyricsJson["songwriters"].arrayObject as? [String] ?? [])
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
