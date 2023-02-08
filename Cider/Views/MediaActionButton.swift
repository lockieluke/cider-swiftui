//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload

enum MediaActionButtonIcon: String {
    
    case Play = "play.fill",
         Shuffle = "shuffle";
    
}

struct MediaActionButton: View {
    
    
    @ObservedObject private var iO = Inject.observer
    
    var icon: MediaActionButtonIcon
    var size: CGFloat? = nil
    var onPress: (() -> Void)? = nil
    
    var body: some View {
        Button {
            
        } label: {
            Image(systemName: icon.rawValue)
                .font(.system(size: size != nil ? size! * 0.5 : 12))
                .foregroundColor(.white)
        }
        .buttonStyle(.borderless)
        .tooltip("\(icon)")
        .frame(width: size ?? 25, height: size ?? 25)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.pink))
        .modifier(SimpleHoverModifier())
        .onTapGesture {
            self.onPress?()
        }
        .enableInjection()
    }
}

struct MediaActionButton_Previews: PreviewProvider {
    static var previews: some View {
        MediaActionButton(icon: .Play)
    }
}
