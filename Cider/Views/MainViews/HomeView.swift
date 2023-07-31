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
    
    struct HomeViewData {
        let personalSocialProfile: AMAPI.SocialProfile?
        let recentlyPlayedItems: [MediaDynamic]
        let personalRecommendation: [MediaPlaylist]
    }
    
    @State private var homeViewData: HomeViewData?
    @State private var dataLoaded = false
    
    @ObservedObject private var iO = Inject.observer
    
    private let onDataLoaded: (() -> Void)?
    
    init(onDataLoaded: (() -> Void)? = nil) {
        self.onDataLoaded = onDataLoaded
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: dataLoaded) {
            VStack(alignment: .leading) {
                HStack {
                    Text("Good \(DateUtils.timeOfDayInWords.lowercased()), \(homeViewData?.personalSocialProfile?.name ?? "")")
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
                            Image(systemSymbol: .ladybug)
                            Text("Report A Bug")
                        }
                    }
                    .buttonStyle(.borderless)
                }
                
                Text("Recently Played")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let recentlyPlayedItems = homeViewData?.recentlyPlayedItems {
                    MediaTableRepresentable(recentlyPlayedItems)
                        .environmentObject(ciderPlayback)
                        .padding(.vertical)
                }
                
                Text("Made For You")
                    .font(.title2.bold())
                PatchedGeometryReader { geometry in
                    HStack {
                        ForEach(homeViewData?.personalRecommendation ?? [], id: \.id) { recommendationItem in
                            MediaPresentable(item: .mediaPlaylist(recommendationItem), maxRelative: geometry.maxRelative.clamped(to: 1000...1300), coverKind: "ss", geometryMatched: true)
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
            // load data in parallel
            async let personalSocialProfile = self.mkModal.AM_API.fetchPersonalSocialProfile()
            async let recentlyPlayedItems = self.mkModal.AM_API.fetchRecentlyPlayed()
            async let personalRecommendation = self.mkModal.AM_API.fetchPersonalRecommendation()
            
            self.homeViewData = await HomeViewData(personalSocialProfile: personalSocialProfile, recentlyPlayedItems: recentlyPlayedItems, personalRecommendation: personalRecommendation)
            self.dataLoaded = true
            self.onDataLoaded?()
        }
        .enableInjection()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
