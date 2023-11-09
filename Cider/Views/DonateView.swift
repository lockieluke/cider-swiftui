//
//  DonateView.swift
//  Cider
//
//  Created by Sherlock LUK on 04/10/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import Defaults
import Inject

struct DonateView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @Environment(\.dismiss) private var dismiss
    
    @Default(.neverShowDonationPopup) private var neverShowDonationPopup
    
    struct DonationData: Identifiable {
        var id: String {
            return self.name
        }
        
        let name: String
        let avatarUrl: URL
        let donationLink: URL
        var isHovering: Bool = false
    }
    @State private var donationDatas: [DonationData] = [
        DonationData(name: "lockieluke", avatarUrl: URL(string: "https://avatars.githubusercontent.com/u/25424409")!, donationLink: URL(string: "https://www.buymeacoffee.com/lockieluke3389")!),
        DonationData(name: "Mono", avatarUrl: URL(string: "https://avatars.githubusercontent.com/u/79590499")!, donationLink: URL(string: "https://www.buymeacoffee.com")!)
    ]
    
    private let onNotToday: (() -> Void)?
    
    init(onNotToday: (() -> Void)? = nil) {
        self.onNotToday = onNotToday
    }
    
    var body: some View {
        VStack {
            Text("Donate directly to Cider for macOS Developers")
                .font(.largeTitle.bold())
                .padding(.top)
            
            Text("We [@lockieluke](https://www.github.com/lockieluke), [@Mono](https://github.com/Monochromish) are the main developers behind this project, making Cider a native app on macOS with SwiftUI.  Currently, we are working voluntarily for this project and does not make a single dime from it, that means we do not receive the same amount of fundings nor the same treatment as the mainline Cider 2 team, we are two separate teams.  The Cider for macOS team would really appreciate your direct donation as a form of motivation or for purchasing new equipment for testing the project on even more devices making sure it works as seamlessly as we wish.")
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .padding(.vertical, 3)
            
            HStack(spacing: 80) {
                ForEach(donationDatas) { donationData in
                    VStack {
                        WebImage(url: donationData.avatarUrl, options: [.fromLoaderOnly])
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                            .frame(width: 100, height: 100)
                        
                        Text("@\(donationData.name)")
                            .padding(.top, 3)
                            .shadow(color: .primary, radius: 10)
                            .padding(3)
                            .background {
                                if donationData.isHovering {
                                    RoundedRectangle(cornerRadius: 10).fill(Color("SecondaryColour"))
                                }
                            }
                    }
                    .onHover { isHovering in
                        self.donationDatas[self.donationDatas.firstIndex { $0.name == donationData.name } ?? 0].isHovering = isHovering
                    }
                    .onTapGesture {
                        donationData.donationLink.open()
                        self.dismiss()
                    }
                }
            }
            .padding(.vertical)
            
            HStack(spacing: 50) {
                Button("Not today") {
                    self.onNotToday?()
                    self.dismiss()
                }
                .buttonStyle(.borderless)
                .tint(.pink)
                
                Button("Don't ask again") {
                    self.dismiss()
                    self.neverShowDonationPopup = true
                }
                .buttonStyle(.borderless)
                .tint(.gray)
            }
            .padding(.vertical)
        }
        .frame(width: 600, height: 430)
        .padding()
        .enableInjection()
    }
}

#Preview {
    DonateView()
}
