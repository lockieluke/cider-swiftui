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
    
    @State private var reorderingIndex: Int?
    @State private var isMovingDown: Bool?
    
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
                .padding(.horizontal)
                
                GeometryReader { scrollGeometry in
                    ScrollView(.vertical) {
                        VStack {
                            if ciderPlayback.queue.isEmpty {
                                Text("Add media to queue")
                                    .frame(height: scrollGeometry.size.height)
                            } else {
                                ForEach(Array(ciderPlayback.queue.enumerated()), id: \.offset) { index, queueTrack in
                                    let allowReordering = Binding<Bool>(get: { index != 0 }, set: { _ in })
                                    if index == reorderingIndex && isMovingDown == false {
                                        Spacer()
                                            .frame(height: 20)
                                    }
                                    
                                    QueueTrackView(track: queueTrack, allowReordering: allowReordering, onReordering: { reorderingIndex in
                                        if reorderingIndex == nil, let lastReorderingIndex = self.reorderingIndex, lastReorderingIndex != 0 {
                                            Task {
                                                await self.ciderPlayback.reorderQueuedItem(from: index, to: lastReorderingIndex)
                                            }
                                        }
                                        
                                        self.isMovingDown = reorderingIndex != nil ? reorderingIndex! > 0 : nil
                                        withAnimation(.interactiveSpring()) {
                                            self.reorderingIndex = reorderingIndex != nil && reorderingIndex != 0 ? index + reorderingIndex! : nil
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(maxHeight: geometry.size.height * 0.95)
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
