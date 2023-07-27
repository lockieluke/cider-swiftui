//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Settings
import Inject

struct GeneralPreferencesPane: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var cacheModal: CacheModal
    
    var body: some View {
        Settings.Container(contentWidth: 450.0) {
            Settings.Section(title: "") {
                Group {
                    PrefSectionText("Cache")
                    Button {
                        self.cacheModal.clear()
                    } label: {
                        Text("Clear Cache")
                    }
                    .disabled(cacheModal.clearedCache)
                    
                    Text("\(Bundle.main.displayName) will have to refetch data next you time it launches and it will take significantly more time to startup")
                        .settingDescription()
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .enableInjection()
    }
}

struct GeneralPreferencesPane_Previews: PreviewProvider {
    static var previews: some View {
        GeneralPreferencesPane()
    }
}
