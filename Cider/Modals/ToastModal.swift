//
//  ToastModal.swift
//  Cider
//
//  Created by Sherlock LUK on 17/01/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import Foundation
import SFSafeSymbols
import SwiftUI

class ToastModal: ObservableObject {
    
    struct Toast {
        let title: String
        let subtitle: String
        let duration: Double
        let icon: SFSymbol?
        let colour: Color
        var isError: Bool = false
        
        init(title: String, subtitle: String, icon: SFSymbol? = nil, duration: Double = 5, colour: Color = .pink) {
            self.title = title
            self.subtitle = subtitle
            self.icon = icon
            self.duration = duration
            self.colour = colour
        }
    }
    
    @Published var toast: Toast? = nil
    @Published var showingToast: Bool = false
    
    func showErrorToast(toast: Toast) {
        var _toast = toast
        _toast.isError = true
        self.showToast(toast: _toast)
    }
    
    func showToast(toast: Toast) {
        self.toast = toast
        self.showingToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(toast.duration))) {
            self.showingToast = false
            self.toast = nil
        }
    }
    
}
