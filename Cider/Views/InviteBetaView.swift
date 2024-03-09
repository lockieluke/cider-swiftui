//
//  InviteBetaView.swift
//  Cider
//
//  Created by Sherlock LUK on 08/03/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject
import FirebaseFirestore
import Lottie
import Defaults

struct InviteBetaView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @Default(.shownInviteBeta) private var shownInviteBeta
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let firestore = Firestore.firestore()
    
    var body: some View {
        WebUIIsland(name: "invite-beta", staticHtml: precompileIncludeStr("@/CiderWebModules/dist/invite-beta.html")) { eventName, dict, webview in
            Task {
                if eventName == "add-invite-beta", let email = dict["email"] as? String {
                    do {
                        let loyalAlphaTesters = self.firestore.collection("app").document("cider").collection("macos-native").document("loyal-alpha-testers")
                        let doc = try await loyalAlphaTesters.getDocument()
   
                        let testers = doc.data()?["testers"] as? [[String: Any]]
                        if testers?.contains(where: { $0["email"] as? String == email }) == false {
                            try await loyalAlphaTesters.updateData([
                                "testers": FieldValue.arrayUnion([[
                                    "email": email,
                                    "mac-serial": Diagnostic.macSerialNumber ?? "not-available",
                                    "timestamp": Timestamp()
                                ]])
                            ])
                        } else {
                            DispatchQueue.main.async {
                                webview.evaluateJavaScript("window.triggerShowAlreadyInvitedDialog()")
                            }
                            return
                        }
                    } catch {
                        print("Failed to add loyal alpha tester: \(error.localizedDescription)")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        webview.evaluateJavaScript("window.doneSubmitting()")
                    }
                }
                
                if eventName == "exit-invite-beta" {
                    self.shownInviteBeta = true
                }
            }
        }
        .background {
            VStack {
                LottieView(animation: try! .from(data: precompileIncludeData("@/Cider/Resources/CiderSpinner.json")))
                    .playing(loopMode: .loop)
                    .clipShape(Rectangle())
                    .frame(width: 25, height: 25)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
        .enableInjection()
    }
}

#Preview {
    InviteBetaView()
}
