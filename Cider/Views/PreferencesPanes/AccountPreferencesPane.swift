//
//  AccountPreferencesPane.swift
//  Cider
//
//  Created by Sherlock LUK on 13/08/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import Settings
import AuthenticationServices
import FirebaseAuth
import Inject
import WebKit

struct AccountPreferencesPane: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var cacheModal: CacheModal
    @EnvironmentObject private var connectModal: ConnectModal
    
    @State private var showingWebView: Bool = false
    
    func signIn(signInMethod: SignInMethod) {
        Task {
            await self.connectModal.signIn(signInMethod: signInMethod) {
                self.connectModal.cleanupWebView()
                self.showingWebView = false
            }
            self.showingWebView = true
        }
    }
    
    var body: some View {
        Settings.Container(contentWidth: 450.0) {
            Settings.Section(title: "") {
                Group {
                    if connectModal.isSignedIn, let user = connectModal.user, let email = user.email, let signInMethod = connectModal.currentSignInMethod?.humanReadableName {
                        Text("Signed in with \(signInMethod): \(email)")
                        
                        Button("Sign Out") {
                            self.connectModal.signOut()
                        }
                    } else {
                        VStack {
                            Image("Cider")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 75, height: 75)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(.vertical)
                            Text("Cider Connect")
                                .font(.title.bold())
                            Text("Sign in to sync preferences and use Cider Remote")
                        }
                        .padding(.vertical)
                        
                        AuthButton(.apple) {
                            self.signIn(signInMethod: .apple)
                        }
                        AuthButton(.google) {
                            self.signIn(signInMethod: .google)
                        }
                        AuthButton(.azure) {
                            if let keyWindow = NSApp.keyWindow {
                                Alert.showModal(on: keyWindow, message: "Sign In with Azure is currently not supported")
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .sheet(isPresented: $showingWebView, onDismiss: {
            self.connectModal.cleanupWebView()
        }) {
            VStack {
                Button() {
                    self.showingWebView = false
                } label: {
                    Image(systemSymbol: .xmarkCircleFill)
                        .font(.title2)
                }
                .buttonStyle(.borderless)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.vertical, 2)
                
                NativeComponent(self.connectModal.view)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: 800, height: 600)
            .padding()
        }
        .enableInjection()
    }
}

struct AccountPreferencesPane_Previews: PreviewProvider {
    static var previews: some View {
        AccountPreferencesPane()
    }
}
