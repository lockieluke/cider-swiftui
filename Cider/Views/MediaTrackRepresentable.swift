//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload

struct MediaTrackRepresentable: View {
    
    @ObservedObject private var iO = Inject.observer
    
    var mediaItem: MediaTrack
    
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    @State private var isHovering = false
    @State private var isClicked = false
    
    var body: some View {
        ResponsiveLayoutReader { windowProp in
            HStack {
                Group {
                    Text("\(mediaItem.title)")
                    Spacer()
                    Text("\(mediaItem.duration.minuteSecond)")
                }
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isHovering ? Color("SecondaryColour").opacity(isClicked ? 0.7 : 0.5) : Color.clear)
                    .animation(.interactiveSpring(), value: isHovering || isClicked)
                    .frame(width: .infinity)
            )
            .onTapGesture {
                Task {
                    await self.ciderPlayback.setQueue(id: self.mediaItem.id, type: self.mediaItem.type)
                    await self.ciderPlayback.play()
                }
            }
            .onHover { isHovering in
                self.isHovering = isHovering
            }
            .modifier(PressActions(onEvent: { isPressed in
                self.isClicked = isPressed
            }))
            .padding(.horizontal)
        }
        .enableInjection()
    }
}

struct MediaTrackRepresentable_Previews: PreviewProvider {
    static var previews: some View {
        MediaTrackRepresentable(mediaItem: MediaTrack(data: []))
    }
}
