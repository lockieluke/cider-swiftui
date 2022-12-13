//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Preferences
import InjectHotReload

struct PrefValueField: View {
    
    @ObservedObject private var iO = Inject.observer
    
    var label: String
    var value: String
    
    init(_ label: String, _ value: String) {
        self.label = label
        self.value = value
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Text("\(label): ")
            Text(value).foregroundColor(.blue).modifier(BasicHoverModifier())
                .onTapGesture {
                    NSPasteboard.general.declareTypes([.string], owner: nil)
                    NSPasteboard.general.setString(value, forType: .string)
                }
        }
        .padding(.top)
        .enableInjection()
    }
    
}

struct DeveloperPreferencesPane: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    
    var body: some View {
        Preferences.Container(contentWidth: 450.0) {
            Preferences.Section(title: "") {
                VStack(alignment: .leading) {
                    Text("Debugging Information")
                        .bold()
                        .padding(.vertical, 3)
                    
                    if let developerToken = mkModal.AM_API.AM_TOKEN,
                       let userToken = mkModal.AM_API.AM_USER_TOKEN {
                        PrefValueField("MusicKit Developer Token", developerToken)
                        PrefValueField("MusicKit User Token", userToken)
                    }
                    
                    Text("Do not share this information with anyone.  The Cider Team would never, never ask for this.")
                        .foregroundColor(.red)
                        .padding(.vertical)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .enableInjection()
    }
    
}

struct DeveloperPreferencesPane_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperPreferencesPane()
    }
}
