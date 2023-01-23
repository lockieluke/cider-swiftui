//
//  InteractiveText.swift
//  Cider
//
//  Created by Sherlock LUK on 23/01/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import InjectHotReload

struct InteractiveText: View {
    
    @ObservedObject private var iO = Inject.observer
    
    var title: String
    @State private var isHovered: Bool = false
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        Text(title)
            .background(RoundedRectangle(cornerRadius: 2).fill(isHovered ? Color("SecondaryColour") : .clear))
            .onHover { isHovered in
                self.isHovered = isHovered
            }
            .enableInjection()
    }
    
}

struct InteractiveText_Previews: PreviewProvider {
    static var previews: some View {
        InteractiveText("")
    }
}
