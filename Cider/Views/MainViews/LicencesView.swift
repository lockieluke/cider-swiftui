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
    
    @State private var showJSLicences: Bool = false
    
    init() {
        self.acknowledgements = Acknowledgement.all()
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Licences")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                Picker("Licences", selection: $showJSLicences) {
                    Text("Swift").tag(false)
                    Text("Web Modules").tag(true)
                }
                .frame(width: 200)
            }
            .padding()
            
            if showJSLicences {
                ScrollView {
                    TextEditor(text: .constant(precompileIncludeStr("@/CiderWebModules/THIRD_PARTY_LICENCES.txt")))
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .disabled(true)
                        .textSelection(.enabled)
                        .introspect(.textEditor, on: .macOS(.v11, .v12, .v13, .v14)) { textEditor in
                            textEditor.backgroundColor = .clear
                        }
                }
            } else {
                List {
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
            }
        }
        .enableInjection()
    }
}

#Preview {
    LicencesView()
}
