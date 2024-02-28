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
    @EnvironmentObject private var navigationModal: NavigationModal
    
    enum LoadingState {
        case loading
        case loaded
        case failed(Error)
    }
    
    struct HomeViewData {
        var personalSocialProfile: AMAPI.SocialProfile?
        var recentlyPlayedItems: [MediaDynamic]
        var personalRecommendation: [MediaPlaylist]
    }
    
    @ObservedObject private var iO = Inject.observer
    
    @State private var homeViewData = HomeViewData(personalSocialProfile: nil, recentlyPlayedItems: [], personalRecommendation: [])
    
    @State private var socialProfileState = LoadingState.loading
    @State private var recentlyPlayedItemsState = LoadingState.loading
    @State private var personalRecommendationState = LoadingState.loading
    
    @Namespace private var mediaAnimationNamespace
    
    func loadHomeViewData() async {
        let personalSocialProfile = await self.mkModal.AM_API.fetchPersonalSocialProfile()
        DispatchQueue.main.async {
            self.homeViewData.personalSocialProfile = personalSocialProfile
            self.socialProfileState = .loaded
        }
        
        let recentlyPlayedItems = await self.mkModal.AM_API.fetchRecentlyPlayed()
        DispatchQueue.main.async {
            self.homeViewData.recentlyPlayedItems = recentlyPlayedItems
            self.recentlyPlayedItemsState = .loaded
        }
        
        let personalRecommendation = await self.mkModal.AM_API.fetchPersonalRecommendation()
        DispatchQueue.main.async {
            self.homeViewData.personalRecommendation = personalRecommendation
            self.personalRecommendationState = .loaded
        }
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                HStack(spacing: 20) {
                    switch socialProfileState {
                    case .loaded:
                        Text("Good \(DateUtils.timeOfDayInWords.lowercased()), \(homeViewData.personalSocialProfile?.name ?? "")")
                            .font(.title)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical)
                    case .loading, .failed:
                        SkeletonView()
                            .frame(width: 200, height: 30)
                    }
                    Spacer()
                    Button {
                        self.navigationModal.isChangelogsViewPresent = true
                    } label: {
                        HStack {
                            Image(systemSymbol: .sparkles)
                            Text("What's New")
                        }
                    }
                    .buttonStyle(.borderless)
                    Button {
                        var components = URLComponents(string: "https://github.com/ciderapp/Cider-2/issues/new")
                        components?.queryItems = [
                            URLQueryItem(name: "assignees", value: "lockieluke"),
                            URLQueryItem(name: "labels", value: "bug,macos"),
                            URLQueryItem(name: "template", value: "bug_report.yaml"),
                            URLQueryItem(name: "title", value: "[Bug] [macOS SwiftUI]: ")
                        ]
                        
                        if Analytics.shared.isArcDefaultBrowser {
                            components?.url?.openInRegularArcWindow()
                        } else {
                            components?.url?.open()
                        }
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
                switch recentlyPlayedItemsState {
                case .loaded:
                    MediaTableRepresentable(homeViewData.recentlyPlayedItems)
                        .padding(.vertical)
                case .loading, .failed:
                    SkeletonView()
                        .frame(height: 150)
                }
                
                Text("Made For You")
                    .font(.title2.bold())
                switch personalRecommendationState {
                case .loaded:
                    PatchedGeometryReader { geometry in
                        HStack {
                            ForEach(homeViewData.personalRecommendation, id: \.id) { recommendationItem in
                                MediaPresentable(item: .mediaPlaylist(recommendationItem), maxRelative: geometry.maxRelative.clamped(to: 1000...1300), coverKind: "ss", animationNamespace: mediaAnimationNamespace)
                            }
                        }
                    }
                case .loading, .failed:
                    SkeletonView()
                        .frame(height: 150)
                }
                Spacer()
            }
            .padding()
        }
        .transparentScrollbars()
        .task {
            await self.loadHomeViewData()
        }
        .enableInjection()
    }
}

struct SkeletonView: View {
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.1))
            .cornerRadius(8)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
