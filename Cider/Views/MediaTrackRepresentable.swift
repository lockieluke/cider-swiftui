//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload

struct MediaTrackRepresentable: View {
    
    @ObservedObject private var iO = Inject.observer
    
    var mediaTrack: MediaTrack
    
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    @State private var isHovering = false
    @State private var isClicked = false
    
    var body: some View {
        HStack {
            Group {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                        .foregroundColor(isHovering ? .pink : .primary)
                        .animation(.interactiveSpring(), value: isHovering)
                    Text("\(mediaTrack.title)")
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
