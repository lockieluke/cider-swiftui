//
//  QueueItemView.swift
//  Cider
//
//  Created by Sherlock LUK on 24/03/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import InjectHotReload

struct QueueItemView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    private let track: MediaTrack
    
    init(track: MediaTrack) {
        self.track = track
    }
    
    var body: some View {
        HStack {
            
        }
        .enableInjection()
    }
}

struct QueueItemView_Previews: PreviewProvider {
    static var previews: some View {
        QueueItemView()
    }
}
