//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload

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
    
    @State private var selectedWSTarget: WSTarget = .CiderPlaybackAgent
    
    var body: some View {
        VStack {
            Picker("Debugging Target", selection: $selectedWSTarget) {
                if ciderPlayback.isReady {
                    Text("CiderPlaybackAgent").tag(WSTarget.CiderPlaybackAgent)
                }
            }
            
            ScrollView(.vertical) {
                ScrollViewReader { scrollValue in
                    if wsModal.traffic.isEmpty {
                        VStack(alignment: .center) {
                            Text("No data has been sent")
                                .foregroundColor(.secondary)
                                .frame(maxHeight: .infinity)
                                .padding()
                        }
                    } else {
                        VStack(alignment: .leading) {
                            ForEach(wsModal.traffic, id: \.id) { traffic in
                                if selectedWSTarget == traffic.target {
                                    WSTrafficView(wsTraffic: traffic)
                                }
                            }
                            
                            Spacer()
                                .id("last")
                        }
                        .onChange(of: wsModal.traffic.count) { _ in
                            scrollValue.scrollTo("last")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
            }
            .transparentScrollbars()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.background)
            .cornerRadius(5)
            
            if ciderPlayback.isReady {
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 7, height: 7)
                    Text("CiderPlaybackAgent is active on port \(Text(verbatim: "\(Int(ciderPlayback.agentPort))"))")
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
