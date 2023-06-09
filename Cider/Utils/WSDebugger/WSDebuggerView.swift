//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload
import Defaults

struct WSTrafficView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    var wsTraffic: WSTrafficRecord
    
    var viewColour: Color {
        get {
            switch wsTraffic.trafficType {
                
            case .Bi:
                return .orange
                
            case .Receive:
                return .green
                
            case .Send:
                return .blue
                
            }
        }
    }
    
    var viewDate: String {
        get {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            return dateFormatter.string(from: wsTraffic.dateSent)
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(wsTraffic.rawJSONString)
                    .textSelection(.enabled)
                Text(viewDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }
            Spacer()
            Text("\(wsTraffic.trafficType.rawValue)")
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).fill(viewColour))
        .enableInjection()
    }
    
}

struct WSDebuggerView: View {
    
    @ObservedObject private var iO = Inject.observer
    @EnvironmentObject private var wsModal: WSModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var appWindowModal: AppWindowModal
    
    #if DEBUG
    @Default(.debugHideFrequentWSRequests) var hideFrequentWSRequests
    #else
    @State private var hideFrequentWSRequests = false
    #endif
    
    @State private var selectedWSTarget: WSTarget = .CiderPlaybackAgent
    
    private let PERFORMANCE_DEMANDING_EVENT_NAMES = ["playbackTimeDidChange"]
    
    var body: some View {
        VStack {
            Picker("Debugging Target", selection: $selectedWSTarget) {
                if ciderPlayback.isReady {
                    Text("CiderPlaybackAgent").tag(WSTarget.CiderPlaybackAgent)
                }
            }
            
            if appWindowModal.isVisibleInViewport {
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading) {
                        ForEach(wsModal.traffic, id: \.identifiableKey) { traffic in
                            if selectedWSTarget == traffic.target {
                                let eventName = traffic.json["eventName"].stringValue
                                let wsTrafficView = WSTrafficView(wsTraffic: traffic)
                                if PERFORMANCE_DEMANDING_EVENT_NAMES.contains(eventName) {
                                    if !self.hideFrequentWSRequests {
                                        wsTrafficView
                                    }
                                } else {
                                    wsTrafficView
                                }
                            }
                        }
                    }
                }
            }
            
            if ciderPlayback.isReady {
                Toggle("Hide frequently sent requests", isOn: $hideFrequentWSRequests)
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 7, height: 7)
                    Text("CiderPlaybackAgent is active on port \(Text(verbatim: "\(Int(ciderPlayback.agentPort))")) - \(appWindowModal.isVisibleInViewport ? String(wsModal.traffic.filter { $0.target == .CiderPlaybackAgent }.count) : "Not Counting") requests")
                }
            }
        }
        .padding()
        .enableInjection()
    }
}

struct WSDebuggerView_Previews: PreviewProvider {
    static var previews: some View {
        WSDebuggerView()
    }
}
