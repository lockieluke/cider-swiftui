//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Settings
import Inject
import Defaults

struct GeneralPreferencesPane: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var cacheModal: CacheModal
    
    @Default(.usePretendardFont) private var usePretendardFont
    
    var body: some View {
        Settings.Container(contentWidth: 450.0) {
            Settings.Section(title: "") {
                Group {
                    PrefSectionText("Appearance")
                    Toggle("Use Pretendard font (Beta)", isOn: $usePretendardFont)
                    Text("Restart is required for changes to take effect")
                        .settingDescription()
                    
                    PrefSectionText("Cache")
                    Button {
                        self.cacheModal.clear()
                    } label: {
                        Text("Clear Cache")
                    }
                    .disabled(cacheModal.clearedCache)
                    
                    Text("\(Bundle.main.displayName) will have to refetch data next time it launches and it will take significantly more time to startup")
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
