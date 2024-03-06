//
//  ExperimentsPreferencesPane.swift
//  Cider
//
//  Created by Sherlock LUK on 05/03/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject
import Settings
import Defaults

struct CiderExperiment: Identifiable, Codable, Hashable, Defaults.Serializable {
    
    static var defaultExperiments: [CiderExperiment] = [
        CiderExperiment(name: "Taylor Swift ban", treatment: "default", treatments: [
            "default",
            "treatment-1"
        ]),
        CiderExperiment(name: "Kinde Auth", treatment: "default", treatments: [
            "default"
        ])
    ]
    
    var id: String {
        self.name.replacingOccurrences(of: " ", with: "-").lowercased()
    }
    
    let name: String
    var treatment: String
    let treatments: [String]?
    
    init(name: String, treatment: String, treatments: [String]? = nil) {
        self.name = name
        self.treatment = treatment
        self.treatments = treatments
    }
    
    static func getExperimentTreatment(id: String) -> String {
        if let savedExperiment = Defaults[.experiments].filter ({ $0.id == id }).first {
            return savedExperiment.treatment
        }
        return self.defaultExperiments.filter ({ $0.id == id }).first!.treatment
    }
    
}

struct CiderExperimentView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    private let experiment: CiderExperiment
    
    init(experiment: CiderExperiment) {
        self.experiment = experiment
    }
    
    @Default(.experiments) private var experiments
    
    var body: some View {
        HStack {
            let experimentTreatment = Binding(get: { () -> String in
                return CiderExperiment.getExperimentTreatment(id: self.experiment.id)
            }, set: { newValue in
                if self.experiments.contains(where: { $0.id == self.experiment.id }) {
                    self.experiments = self.experiments.map {
                        if $0.id == self.experiment.id {
                            var modifyingExperiment = experiment
                            modifyingExperiment.treatment = newValue
                            return modifyingExperiment
                        }
                        
                        return $0
                    }
                } else {
                    var modExperiment = self.experiment
                    modExperiment.treatment = newValue
                    self.experiments.append(modExperiment)
                }
            })
            Text("\(experiment.name)")
            Spacer()
            Picker("", selection: experimentTreatment) {
                ForEach(experiment.treatments ?? [], id: \.self) { treatment in
                    Text(treatment).tag(treatment)
                }
            }
            .controlSize(.regular)
            .frame(maxWidth: 150)
        }
        .padding(.vertical, 7)
        .enableInjection()
    }
}

struct ExperimentsPreferencesPane: View {
    
    @ObservedObject private var iO = Inject.observer
    
    var body: some View {
        Settings.Container(contentWidth: 450.0) {
            Settings.Section(title: "") {
                List {
                    Text("Local Experiments")
                        .bold()
                        .padding(.vertical, 5)
                    ForEach(CiderExperiment.defaultExperiments) { defaultExperiment in
                        CiderExperimentView(experiment: defaultExperiment)
                    }
                    Text("Remote Feature Flags")
                        .bold()
                        .padding(.vertical, 5)
                }
                .frame(height: 500)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
        .enableInjection()
    }
}

#Preview {
    ExperimentsPreferencesPane()
}
