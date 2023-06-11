//
//  QueueView.swift
//  Cider
//
//  Created by Sherlock LUK on 18/03/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject
import Defaults

struct QueueView: View {
    
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    @ObservedObject private var iO = Inject.observer
    
    @State private var reorderingIndex: Int?
    @State private var isMovingDown: Bool?
    
    var body: some View {
        SidePane(title: "Queue", content: {
            GeometryReader { scrollGeometry in
                ScrollView(.vertical) {
                    VStack {
                        if ciderPlayback.queue.isEmpty {
                            Text("Add media to queue")
                                .frame(height: scrollGeometry.size.height)
                        } else {
                            ForEach(Array(ciderPlayback.queue.enumerated()), id: \.offset) { index, queueTrack in
                                let allowReordering = Binding<Bool>(get: { index != self.ciderPlayback.queue.startIndex }, set: { _ in })
                                if index == reorderingIndex && isMovingDown == false {
                                    Spacer()
                                        .frame(height: 20)
                                }
                                
                                QueueTrackView(track: queueTrack, allowReordering: allowReordering, onReordering: { reorderingIndex in
                                    if reorderingIndex == nil, let lastReorderingIndex = self.reorderingIndex, lastReorderingIndex != 0, self.ciderPlayback.queue.indices.contains(lastReorderingIndex) {
                                        Task {
                                            await self.ciderPlayback.reorderQueuedItem(from: index, to: lastReorderingIndex)
                                        }
                                    }
                                    
                                    self.isMovingDown = reorderingIndex != nil ? reorderingIndex! > 0 : nil
                                    withAnimation(.interactiveSpring()) {
                                        self.reorderingIndex = reorderingIndex != nil && reorderingIndex != 0 ? index + reorderingIndex! : nil
                                    }
                                }, onPlay: {
                                    Task {
                                        await self.ciderPlayback.skipToQueueIndex(index)
                                    }
                                })
                                .frame(maxWidth: scrollGeometry.size.width * 0.9)
                                
                                if index == reorderingIndex && isMovingDown == true {
                                    Spacer()
                                        .frame(height: 20)
                                }
                            }
                        }
                    }
                    .frame(width: scrollGeometry.size.width)
                    
                    Spacer()
                        .frame(height: 50)
                }
            }
        }, headerChildren: {
            Button {
                Task {
                    await self.ciderPlayback.setAutoPlay(!self.ciderPlayback.playbackBehaviour.autoplayEnabled)
                    Defaults[.playbackAutoplay] = self.ciderPlayback.playbackBehaviour.autoplayEnabled
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
        })
    }
}

struct QueueView_Previews: PreviewProvider {
    static var previews: some View {
        QueueView()
    }
}
