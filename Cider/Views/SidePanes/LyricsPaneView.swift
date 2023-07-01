//
//  LyricsView.swift
//  Cider
//
//  Created by Sherlock LUK on 01/04/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject
import SwiftyJSON
import WrappingHStack

struct LyricLineData {
    let id: String
    let line: String
    let startTime: Float
    let endTime: Float
}

struct LyricsData {
    let id: String
    let lyrics: [LyricLineData]
    let leadingSilence: Float
    let songwriters: [String]
}

struct LyricLine: View {
    
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    private let lyric: LyricLineData
    private let active: Bool
    
    init(_ lyric: LyricLineData, active: Bool) {
        self.lyric = lyric
        self.active = active
    }
    
    var body: some View {
        Text(lyric.line)
            .fontWeight(.bold)
            .foregroundColor(active ? .primary : .secondary)
            .font(.title)
            .blur(radius: active ? .zero : 3)
            .animation(.spring(), value: active)
    }
    
}

struct LyricsPaneView: View {
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    #if os(macOS)
    @EnvironmentObject private var nativeUtilsWrapper: NativeUtilsWrapper
    #endif
    
    @ObservedObject private var iO = Inject.observer
    
    @State private var lyricsData: LyricsData?
    @State private var lastSyncedId: String?
    
    var body: some View {
        SidePane(content: {
            if let lyricsData = self.lyricsData {
                GeometryReader { geometry in
                    VStack {
                        if !lyricsData.songwriters.isEmpty {
                            WrappingHStack(["Songwriters: "] + lyricsData.songwriters, id: \.self) { songwriter in
                                Text(songwriter)
                                    .italic()
                            }
                            .padding(.horizontal)
                        }
                        
                        ScrollViewReader { proxy in
                            ScrollView(.vertical, showsIndicators: false) {
                                let seconds = Float(ciderPlayback.nowPlayingState.currentTime ?? 0.0)
                                
                                VStack(alignment: .leading, spacing: 20) {
                                    ForEach(Array(lyricsData.lyrics.enumerated()), id: \.offset) { i, lyric in
                                        let isActive = lyric.startTime...lyric.endTime ~= seconds
                                        
                                        LyricLine(lyric, active: isActive)
                                            .id(i)
                                            .onChange(of: isActive) { newIsActive in
                                                if newIsActive {
                                                    DispatchQueue.main.async {
                                                        withAnimation(.linear) {
                                                            proxy.scrollTo(i, anchor: .top)
                                                        }
                                                    }
                                                }
                                            }
                                    }
                                }
                                .padding()
                            }
                            .padding(.vertical, 2)
                            .mask {
                                LinearGradient(
                                    stops: [
                                        Gradient.Stop(color: .clear, location: .zero),
                                        Gradient.Stop(color: .black, location: 0.01),
                                        Gradient.Stop(color: .black, location: 0.1),
                                        Gradient.Stop(color: .clear, location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }
                        }
                        
                    }
                    .padding(.vertical)
                }
            }
        })
        .task {
            #if os(macOS)
            if let item = self.ciderPlayback.nowPlayingState.item, item.id != self.lyricsData?.id, let lyricsXml = await self.mkModal.AM_API.fetchLyricsXml(item: item) {
                let lyricsJson = JSON(parseJSON: self.nativeUtilsWrapper.nativeUtils.parse_lyrics_xml(lyricsXml).toString())
                self.lyricsData = LyricsData(id: item.id, lyrics: lyricsJson["lyrics"].arrayValue.compactMap { line in
                    return LyricLineData(id: line["id"].stringValue, line: line["line"].stringValue, startTime: line["start_time"].floatValue, endTime: line["end_time"].floatValue)
                }, leadingSilence: lyricsJson["leadingSilence"].floatValue, songwriters: lyricsJson["songwriters"].arrayObject as? [String] ?? [])
            }
            #endif
        }
        .enableInjection()
    }
}

struct LyricsView_Previews: PreviewProvider {
    static var previews: some View {
        LyricsPaneView()
    }
}
