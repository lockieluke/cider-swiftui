//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject

struct MediaTrackRepresentable: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var mkModal: MKModal
    
    @State private var mediaTrack: MediaTrack
    @State private var isHovering = false
    @State private var isClicked = false
    
    init(mediaTrack: MediaTrack) {
        self.mediaTrack = mediaTrack
    }
    
    var body: some View {
        HStack {
            Group {
                HStack {
                    Image(systemSymbol: .playFill)
                        .font(.system(size: 14))
                        .foregroundColor(isHovering ? .pink : .primary)
                        .animation(.interactiveSpring(), value: isHovering)
                    VStack {
                        Group {
                            Text("\(mediaTrack.title)")
                            ArtistNamesInteractiveText(item: .mediaTrack(mediaTrack))
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
                await self.ciderPlayback.setQueue(item: .mediaTrack(self.mediaTrack))
                await self.ciderPlayback.clearAndPlay(item: .mediaTrack(self.mediaTrack))
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
