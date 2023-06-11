//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject

enum ButtonAction : String {
    
    case Back = "chevron.backward",
    Forward = "chevron.forward",
    More = "ellipsis.circle",
    Library = "sidebar.squares.leading",
    AirPlay = "airplayaudio",
    Queue = "list.bullet",
    Lyrics = "quote.bubble";
    
}

struct ActionButton: View {
    
    @ObservedObject private var iO = Inject.observer
    
    private let actionType: ButtonAction
    private let onClick: (() -> Void)?
    
    @State private var isHovered = false
    @State private var isClicked = false
    @Binding private var enabled: Bool
    
    init(actionType: ButtonAction = .More, enabled: Binding<Bool> = .constant(false), _ onClick: (() -> Void)? = nil) {
        self.actionType = actionType
        self._enabled = enabled
        self.onClick = onClick
    }
    
    var body: some View {
        Rectangle()
            .fill(Color("PrimaryColour"))
            .opacity(isClicked || enabled ? 1 : (isHovered ? 0.7 : 0))
            .cornerRadius(5)
            .tooltip("\(actionType)")
            .overlay {
                Image(systemName: actionType.rawValue)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
            }
            .onTapGesture {
                onClick?()
            }
            .modifier(PressActions(onEvent: { isPressed in
                self.isClicked = isPressed
            }))
            .onHover { isHovered in
                self.isHovered = isHovered
            }
            .frame(width: 35, height: 30)
            .enableInjection()
    }
}

struct ActionButton_Previews: PreviewProvider {
    static var previews: some View {
        ActionButton()
    }
}
