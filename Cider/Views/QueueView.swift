//
//  QueueView.swift
//  Cider
//
//  Created by Sherlock LUK on 18/03/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import InjectHotReload

struct QueueView: View {
    
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    @ObservedObject private var iO = Inject.observer
    
    var body: some View {
        PatchedGeometryReader { geometry in
            VStack {
                HStack {
                    Text("Queue")
                        .font(.title.bold())
                    Spacer()
                    Button {
                        Task {
                            await self.ciderPlayback.setAutoPlay(!self.ciderPlayback.playbackBehaviour.autoplayEnabled)
                        }
                    } label: {
                        Image(systemName: "infinity")
                            .padding()
                            .frame(width: 25, height: 25)
                            .background(.thickMaterial)
                            .foregroundColor(ciderPlayback.playbackBehaviour.autoplayEnabled ? .pink : .white)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                GeometryReader { scrollGeometry in
                    ScrollView(.vertical) {
                        if ciderPlayback.queue.isEmpty {
                            Text("Add media to queue")
                                .frame(height: scrollGeometry.size.height)
                        } else {
                            ForEach(ciderPlayback.queue, id: \.id) { queueTrack in
                                Text(queueTrack.title)
                            }
                        }
                    }
                    .frame(width: scrollGeometry.size.width)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .frame(height: geometry.size.height * 0.95)
            .frame(width: (geometry.maxRelative * 0.2).clamped(to: 275...320))
            .background(.ultraThinMaterial)
            .shadow(radius: 7)
            .cornerRadius(10)
        }
        .padding(.trailing, 10)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .enableInjection()
    }
}

struct QueueView_Previews: PreviewProvider {
    static var previews: some View {
        QueueView()
    }
}
