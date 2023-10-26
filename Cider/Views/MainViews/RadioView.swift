//
//  BrowseView.swift
//  Cider
//
//  Created by Sherlock LUK on 28/07/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject

struct RadioView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    
    @State private var allRadioData: [MediaRadioData] = []
    
    @Namespace private var animationNamespace
    
    let heroCardSize: CGSize = CGSize(width: 550, height: 225)
    let coverKindValue: String = "bb"
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                Text("Radio")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                PatchedGeometryReader { geometry in
                    ForEach(Array(allRadioData.enumerated()), id: \.offset) { index, data in
                        let kind = data.kind.rawValue
                        let items = data.items
                        
                        if kind == "326" {
                            Text(data.name)
                                .font(.title2.bold())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 15)
                        }
                        
                        let displayable = kind == "488" || kind == "326"
                        
                        if displayable {
                            ScrollView(.horizontal) {
                                LazyHStack {
                                    ForEach(items, id: \.id) { item in
                                        if case let .mediaStation(mediaStation) = item {
                                            if kind == "488" {
                                                HeroCard(
                                                    item: BrowseItemAttributes(
                                                        designBadge: "",
                                                        name: mediaStation.title,
                                                        id: mediaStation.id,
                                                        kind: "stations",
                                                        artistName: "",
                                                        url: "",
                                                        artistUrl: "",
                                                        artistId: "",
                                                        subscriptionHero: mediaStation.editorialArtwork.subscriptionHero.getUrlWithDefaultSize().absoluteString,
                                                        plainEditorialNotes: mediaStation.editorialNotes.short
                                                    ),
                                                    geometryMatching: animationNamespace,
                                                    originalSize: heroCardSize,
                                                    coverKind: coverKindValue,
                                                    maxRelative: geometry.maxRelative
                                                )
                                                .padding(.horizontal)
                                            }
                                        }
                                        
                                        if kind == "326" {
                                            MediaPresentable(item: item, maxRelative: geometry.maxRelative, isHostOrArtist: item.type == MediaType.AppleCurator.rawValue)
                                                .padding()
                                        }
                                    }
                                    .padding(.vertical)
                                }
                            }
                            .transparentScrollbars()
                        }
                    }
                }
            }
            .padding()
        }
        .transparentScrollbars()
        .task {
            self.allRadioData = await mkModal.AM_API.fetchRadio()
        }
        .enableInjection()
    }
    
}

struct RadioView_Previews: PreviewProvider {
    static var previews: some View {
        BrowseView()
    }
}
