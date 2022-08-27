//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject

enum TitleBarAction : String {
    
    case Back = "chevron.backward";
    case Forward = "chevron.forward";
    case More = "ellipsis.circle";
    case Library = "sidebar.squares.leading";
    
}

struct TitleBarActionButton: View {
    
    @ObservedObject private var iO = Inject.observer
    
    public var actionType: TitleBarAction = .More
    public var onClick: (() -> Void)? = nil
    
    @State private var isHovered = false
    @State private var isClicked = false
    
    var body: some View {
        Rectangle()
            .fill(Color("PrimaryColour"))
            .opacity(isClicked ? 0.5 : (isHovered ? 1 : 0))
            .cornerRadius(5)
            .overlay {
                Image(systemName: actionType.rawValue)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
            }
            .onTapGesture {
                onClick?()
            }
            .onHover { isHovered in
                self.isHovered = isHovered
            }
            .gesture(DragGesture(minimumDistance: 0).onChanged({_ in
                self.isClicked = true
            }).onEnded({_ in
                self.isClicked = false
            }))
            .frame(width: 35, height: 30)
            .enableInjection()
    }
}

struct TitleBarActionButton_Previews: PreviewProvider {
    static var previews: some View {
        TitleBarActionButton()
    }
}
