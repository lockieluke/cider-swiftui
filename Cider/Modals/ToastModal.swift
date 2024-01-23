//
//  ToastModal.swift
//  Cider
//
//  Created by Sherlock LUK on 17/01/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import Foundation

class ToastModal: ObservableObject {
    
    struct ErrorToast {
        let title: String
        let subtitle: String
        let duration: Double = 5
    }
    @Published var errorToast: ErrorToast? = nil
    @Published var showingErrorToast: Bool = false
    
    func showErrorToast(errorToast: ErrorToast) {
        self.errorToast = errorToast
        self.showingErrorToast = true
    }
    
}
