//
//  CiderPlayground.swift
//  Cider
//
//  Created by Sherlock LUK on 29/07/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject

struct CiderPlayground: View {
    
    struct CiderPlaygroundTestAction {
        let name: String
        let description: String
        let action: () async -> Any?
    }
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    
    @State private var showResults: Bool = false
    @State private var currentTestAction: CiderPlaygroundTestAction?
    @State private var loadingResults: Bool = false
    @State private var results: Any?
    
    private let testActions: [CiderPlaygroundTestAction]
    
    init(testActions: [CiderPlaygroundTestAction] = []) {
        self.testActions = testActions
    }
    
    var sheetView: some View {
        VStack {
            ScrollView(.vertical) {
                Text(results.debugDescription)
                    .textSelection(.enabled)
                Spacer()
            }
            HStack {
                Spacer()
                Button("Done") {
                    self.showResults = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Cider Playgrounds")
                .font(.title.bold())
                .padding()
            List {
                ForEach(self.testActions, id: \.name.localizedLowercase) { testAction in
                    VStack(alignment: .leading) {
                        Text(testAction.name)
                            .font(.title2.bold())
                        Text(testAction.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Button {
                            Task {
                                self.currentTestAction = testAction
                                self.loadingResults = true
                                self.results = "No Results"
                                if let results = await testAction.action() {
                                    self.results = unwrapAny(results)
                                }
                                self.showResults = true
                                self.loadingResults = false
                            }
                        } label: {
                            if currentTestAction?.name == testAction.name && loadingResults {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .controlSize(.small)
                            } else {
                                Text("Run")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(currentTestAction?.name != testAction.name && loadingResults)
                        .padding(.vertical)
                    }
                }
            }
            .introspect(.list, on: .macOS(.v10_15, .v11, .v12, .v13, .v14)) { list in
                list.backgroundColor = .clear
            }
            .listStyle(.sidebar)
        }
        .background(VisualEffectBackground(material: .fullScreenUI).edgesIgnoringSafeArea(.top))
        .sheet(isPresented: $showResults, onDismiss: {
            self.currentTestAction = nil
        }) {
            sheetView
        }
        .enableInjection()
    }
}

struct CiderPlayground_Previews: PreviewProvider {
    static var previews: some View {
        CiderPlayground()
    }
}
