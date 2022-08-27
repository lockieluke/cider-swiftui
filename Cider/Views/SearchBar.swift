//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject
import Introspect

struct SearchBar: View {
    
    @ObservedObject private var iO = Inject.observer
    @ObservedObject public var searchModal: SearchModal
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField("Search", text: $searchModal.currentSearchText)
            .textFieldStyle(.plain)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .contentShape(Rectangle())
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color("SecondaryColour"))
                    .onTapGesture {
                        self.isFocused = true
                    }
            }
            .focused($isFocused)
            .introspectTextField { textField in
                textField.becomeFirstResponder()
            }
            .onHover { isHovered in
                if isHovered {
                    NSCursor.iBeam.push()
                } else {
                    NSCursor.pop()
                }
            }
            .padding(.horizontal, 10)
            .enableInjection()
    }
}

struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar(searchModal: .shared)
    }
}
