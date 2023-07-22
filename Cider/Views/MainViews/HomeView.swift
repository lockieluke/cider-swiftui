//
//  HomeView.swift
//  Cider
//
//  Created by Sherlock LUK on 15/07/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject

struct HomeView: View {
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    @State private var personalSocialProfile: AMAPI.SocialProfile?
    @State private var recentlyPlayedItems: [MediaDynamic] = []
    @State private var personalRecommendation: [MediaPlaylist] = []
    @State private var dataLoaded = false
    
    @ObservedObject private var iO = Inject.observer
    
    var body: some View {
        ScrollView(.vertical) {
            VStack {
                HStack {
                    Text("Good \(DateUtils.timeOfDayInWords.lowercased()), \(personalSocialProfile?.name ?? "")")
                        .font(.title)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical)
                    Spacer()
                    Button {
                        let newIssueUrl = URL(string: "https://github.com/ciderapp/Cider-2/issues/new?assignees=&labels=\("🕓+Pending+Implementation,🐛+Bug".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)&template=bug_report.yaml&title=\("[Bug] [macOS SwiftUI]:".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)")
                        
                        newIssueUrl?.open()
                    } label: {
                        HStack {
                            Image(systemName: "ladybug")
                            Text("Report A Bug")
                        }
                    }
                    .buttonStyle(.borderless)
                }
                VStack(alignment: .leading, spacing: 20) {
                    Text("Recently Played")
                        .font(.title2.bold())
                    MediaTableRepresentable(recentlyPlayedItems)
                        .environmentObject(ciderPlayback)
                    
                    Text("Made For You")
                        .font(.title2.bold())
                    PatchedGeometryReader { geometry in
                        HStack {
                            ForEach(personalRecommendation, id: \.id) { recommendationItem in
                                MediaPresentable(item: .mediaPlaylist(recommendationItem), maxRelative: geometry.maxRelative.clamped(to: 1000...1300), coverKind: "ss", geometryMatched: true)
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding()
            .opacity(dataLoaded ? 1 : 0)
            .animation(.easeIn, value: dataLoaded)
        }
        .transparentScrollbars()
        .task {
            self.personalSocialProfile = await self.mkModal.AM_API.fetchPersonalSocialProfile()
            self.recentlyPlayedItems = await self.mkModal.AM_API.fetchRecentlyPlayed()
            self.personalRecommendation = await self.mkModal.AM_API.fetchPersonalRecommendation()
            self.dataLoaded = true
        }
        .enableInjection()
    }
}

#Preview {
    HomeView()
}
