//
//  BannedView.swift
//  Cider
//
//  Created by Sherlock LUK on 06/03/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject

struct BannedView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    var body: some View {
        VStack {
            Image(systemSymbol: .xCircle)
                .font(.system(size: 60, weight: .light, design: .rounded))
                .foregroundStyle(.red)
                .padding(.vertical, 5)
            
            Text("You're banned")
                .font(.largeTitle)
                .bold()
            
            Text("You've been permenantly banned from using \(Bundle.main.displayName) because you listened to **Taylor Swift**")
                .padding(.vertical, 1)
        }
        .task {
            await self.ciderPlayback.playbackEngine.stop()
            self.ciderPlayback.shutdown()
        }
        .enableInjection()
    }
}

#Preview {
    BannedView()
}
