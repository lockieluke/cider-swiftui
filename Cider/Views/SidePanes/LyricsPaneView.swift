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
import Throttler
import Foundation
import ZippyJSON

struct LyricData: Codable {
    let leadingSilence: Double
    let lyrics: [Lyric]
    let songwriters: [String]
    
}

struct Lyric: Codable {
    let endTime: Double
    let id: UUID
    let line: String
    let startTime: Double
    
    enum CodingKeys: String, CodingKey {
        case endTime = "end_time"
        case id
        case line
        case startTime = "start_time"
    }
}

struct LyricLine: View {
    
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    @State private var isHovering: Bool = false
    
    private let lyric: Lyric
    private let active: Bool
    
    init(_ lyric: Lyric, active: Bool) {
        self.lyric = lyric
        self.active = active
    }
    
    var body: some View {
        Text(lyric.line)
            .fontWeight(.bold)
            .foregroundColor(active ? .primary : .secondary)
            .font(.title)
            .blur(radius: active ? .zero : 2)
            .animation(.spring(), value: active)
            .background(RoundedRectangle(cornerRadius: 10).fill(.gray.opacity(isHovering ? 0.2 : 0)))
            .onHover { isHovering in
                withAnimation(.interactiveSpring) {
                    self.isHovering = isHovering
                }
            }
            .onTapGesture {
                Task {
                    await self.ciderPlayback.playbackEngine.seekToTime(seconds: Int(lyric.startTime))
                }
            }
    }
    
}

struct LyricsPaneView: View {
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
#if os(macOS)
    @EnvironmentObject private var nativeUtilsWrapper: NativeUtilsWrapper
#endif
    
    @ObservedObject private var iO = Inject.observer
    
    @State private var lyricsData: LyricData?
    
    var body: some View {
        SidePane(content: {
            if let lyricData = self.lyricsData {
                GeometryReader { geometry in
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            let seconds = Float(ciderPlayback.nowPlayingState.currentTime ?? 0.0)
                            
                            VStack(alignment: .leading, spacing: 20) {
                                ForEach(Array(lyricData.lyrics.enumerated()), id: \.offset) {i, lyric in
                                    let isActive = lyric.startTime...lyric.endTime ~= Double(seconds)
                                    
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
                                
                                if !lyricData.songwriters.isEmpty {
                                    WrappingHStack(["Songwriters: "] + lyricData.songwriters, id: \.self) { songwriter in
                                        Text(songwriter)
                                            .italic()
                                    }
                                }
                            }
                            .padding()
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .padding(.vertical)
                    }
                }
            }
        })
        .onChange(of: ciderPlayback.nowPlayingState.item?.id) { _ in
            Debouncer.debounce {
                if let songId = ciderPlayback.nowPlayingState.item?.id {
                    fetchLyrics(for: songId)
                }
            }
        }
        .task {
            self.fetchLyrics(for: ciderPlayback.nowPlayingState.item?.id)
        }
        .enableInjection()
    }
    
    func fetchLyrics(for songId: String?) {
#if os(macOS)
        guard let songId = songId else { return }
        
        Task {
            if let lyrics = await mkModal.AM_API.fetchLyrics(id: songId) {
                let lyricsJson = JSON(nativeUtilsWrapper.nativeUtils.parse_lyrics_xml(lyrics).toString())
                do {
                    if let jsonString = lyricsJson.rawString() {
                        if let jsonData = jsonString.data(using: .utf8) {
                            self.lyricsData = try ZippyJSONDecoder().decode(LyricData.self, from: jsonData)
                        }
                    }
                } catch {
                    print("Error: \(error)")
                }
            }
        }
#endif
    }
}

struct LyricsView_Previews: PreviewProvider {
    static var previews: some View {
        LyricsPaneView()
    }
}
