//
//  LicencesView.swift
//  Cider
//
//  Created by Sherlock LUK on 09/03/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject
import AckGen

struct LicencesView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    private let acknowledgements: [Acknowledgement]
    
    init() {
        self.acknowledgements = Acknowledgement.all()
    }
    
    var body: some View {
        List {
            Text("Licences")
                .font(.largeTitle)
                .bold()
                .padding(.vertical, 5)
            ForEach(acknowledgements, id: \.title) { acknowledgement in
                Text(acknowledgement.title)
                    .font(.title)
                    .padding(.bottom, 10)
                Text(acknowledgement.license)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .listStyle(.plain)
        .introspect(.list, on: .macOS(.v10_15, .v11, .v12, .v13, .v14)) { list in
            list.backgroundColor = .clear
            list.enclosingScrollView?.drawsBackground = false
            list.enclosingScrollView?.backgroundColor = .clear
        }
        .enableInjection()
    }
}

#Preview {
    LicencesView()
}
