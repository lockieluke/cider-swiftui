//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject

enum ButtonAction : String {
    
    case Back = "chevron.backward";
    case Forward = "chevron.forward";
    case More = "ellipsis.circle";
    case Library = "sidebar.squares.leading";
    case AirPlay = "airplayaudio";
    case Queue = "list.bullet";
    
}

struct ActionButton: View {
    
    @ObservedObject private var iO = Inject.observer
    
    public var actionType: ButtonAction = .More
    public var onClick: (() -> Void)? = nil
    
    @State private var isHovered = false
    @State private var isClicked = false
    
    var body: some View {
        Rectangle()
            .fill(Color("PrimaryColour"))
            .opacity(isClicked ? 1 : (isHovered ? 0.7 : 0))
            .cornerRadius(5)
            .overlay {
                Image(systemName: actionType.rawValue)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
            }
            .gesture(DragGesture(minimumDistance: 0).onChanged({_ in
                self.isClicked = true
            }).onEnded({_ in
                self.isClicked = false
            }))
            .onTapGesture {
                onClick?()
            }
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
