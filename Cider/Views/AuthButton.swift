//
//  AuthButton.swift
//  Cider
//
//  Created by Sherlock LUK on 19/08/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject

struct AuthButton: View {
    
    @ObservedObject private var iO = Inject.observer
    
    enum AuthType {
        case apple, google, azure, appleMusic
        
        var name: String {
            switch self {
            case .apple:
                return "Apple"
            case .google:
                return "Google"
            case .azure:
                return "Azure"
                
            case .appleMusic:
                return "Apple Music"
            }
        }
        
        var icon: AnyView {
            switch self {
            case .apple:
                return AppleIcon()
                    .fill(.white)
                    .frame(width: 20, height: 20)
                    .erasedToAnyView()
            case .google:
                return Image("Google")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .erasedToAnyView()
            case .azure:
                return Image("Azure")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .erasedToAnyView()
                
            case .appleMusic:
                return Image("AppleMusic")
                    .antialiased(true)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 20)
                    .drawingGroup()
                    .erasedToAnyView()
            }
        }
    }
    
    private let authType: AuthType
    private let onClick: (() -> Void)?
    
    init(_ authType: AuthType, _ onClick: (() -> Void)? = nil) {
        self.authType = authType
        self.onClick = onClick
    }
    
    var body: some View {
        HStack {
            authType.icon
            
            Text("Sign in with \(authType.name)")
                .foregroundStyle(.white)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 5).fill(.black).frame(minWidth: 170))
        .onTapGesture {
            self.onClick?()
        }
        .modifier(TapEffectModifier())
        .contentShape(RoundedRectangle(cornerRadius: 5))
        .enableInjection()
    }
}
