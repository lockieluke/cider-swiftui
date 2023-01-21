//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload

struct SearchBar: View {
    
    @ObservedObject private var iO = Inject.observer
    @EnvironmentObject private var searchModal: SearchModal
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        PatchedGeometryReader { geometry in
            TextField("Search", text: $searchModal.currentSearchText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 10)
                .frame(width: geometry.size.width * 0.2, height: 30)
                .contentShape(Rectangle())
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color("SecondaryColour"))
                        .onTapGesture {
                            self.isFocused = true
                        }
                }
                .focused($isFocused)
                .onHover { isHovered in
                    if isHovered {
                        NSCursor.iBeam.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .onAppear {
                    self.isFocused = true
                }
                .padding(.horizontal, 10)
        }
        .enableInjection()
    }
}

struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar()
            .environmentObject(SearchModal())
    }
}
