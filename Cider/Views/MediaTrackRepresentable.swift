//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload

struct MediaTrackRepresentable: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var mkModal: MKModal
    
    @State private var mediaTrack: MediaTrack
    @State private var isHovering = false
    @State private var isClicked = false
    @State private var showArtistPicker = false
    
    init(mediaTrack: MediaTrack) {
        self.mediaTrack = mediaTrack
    }
    
    var body: some View {
        HStack {
            Group {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                        .foregroundColor(isHovering ? .pink : .primary)
                        .animation(.interactiveSpring(), value: isHovering)
                    VStack {
                        Group {
                            Text("\(mediaTrack.title)")
                            InteractiveText("\(mediaTrack.artistName)")
                                .font(.system(.caption))
                                .opacity(0.8)
                                .onTapGesture {
                                    Task {
                                        if let detailedMediaTrack = try? await self.mkModal.AM_API.fetchSong(id: self.mediaTrack.id) {
                                            withAnimation(.interactiveSpring()) {
                                                self.mediaTrack = detailedMediaTrack
                                                if detailedMediaTrack.artistsData.count > 1 {
                                                    self.showArtistPicker.toggle()
                                                } else {
                                                    self.navigationModal.appendViewStack(NavigationStack(stackType: .Artist, isPresent: true, params: ArtistViewParams(originMediaItem: .mediaTrack(detailedMediaTrack))))
                                                }
                                            }
                                        }
                                    }
                                }
                                .popover(isPresented: $showArtistPicker, attachmentAnchor: .point(.center), arrowEdge: .bottom) {
                                    VStack {
                                        let artistNames = self.mediaTrack.artistName.components(separatedBy: " & ")
                                        ForEach(0..<artistNames.count, id: \.self) { index in
                                            InteractiveText(artistNames[index])
                                                .onTapGesture {
                                                    self.showArtistPicker = false
                                                    self.navigationModal.appendViewStack(NavigationStack(stackType: .Artist, isPresent: true, params: ArtistViewParams(originMediaItem: .mediaTrack(self.mediaTrack), selectingArtistIndex: index)))
                                                }
                                        }
                                    }
                                    .padding()
                                }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }
                Spacer()
                Text("\(mediaTrack.duration.minuteSecond)")
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isHovering ? Color("SecondaryColour").opacity(isClicked ? 0.7 : 0.5) : Color.clear)
                .animation(.interactiveSpring(), value: isHovering || isClicked)
        )
        .onTapGesture {
            Task {
                await self.ciderPlayback.setQueue(mediaTrack: self.mediaTrack)
                await self.ciderPlayback.clearAndPlay(mediaTrack: self.mediaTrack)
            }
        }
        .onHover { isHovering in
            self.isHovering = isHovering
        }
        .modifier(PressActions(onEvent: { isPressed in
            self.isClicked = isPressed
        }))
        .padding(.horizontal)
        .enableInjection()
    }
}

struct MediaTrackRepresentable_Previews: PreviewProvider {
    static var previews: some View {
        MediaTrackRepresentable(mediaTrack: MediaTrack(data: []))
    }
}
