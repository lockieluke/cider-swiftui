//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Settings
import InjectHotReload

struct GeneralPreferencesPane: View {
    
    @ObservedObject private var iO = Inject.observer
    
    var body: some View {
        Settings.Container(contentWidth: 450.0) {
            
        }
        .enableInjection()
    }
}

struct GeneralPreferencesPane_Previews: PreviewProvider {
    static var previews: some View {
        GeneralPreferencesPane()
    }
}
