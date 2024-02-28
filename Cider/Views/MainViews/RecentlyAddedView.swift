//
//  RecentlyAddedView.swift
//  Cider
//
//  Created by Sherlock LUK on 27/02/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject
import Lottie
import Throttler

struct RecentlyAddedView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    
    @State private var recentlyAddedItems: [MediaDynamic] = []
    @State private var searchResultItems: [MediaDynamic] = []
    @State private var isFetching: Bool = false
    @State private var isSearching: Bool = false
    @State private var searchTerm: String = ""
    
    var body: some View {
        PatchedGeometryReader { geometry in
            VStack {
                HStack {
                    Text("**Recently Added**\(searchResultItems.isEmpty ? "" : " - Searching for \"\(searchTerm)\"")")
                        .font(.title2)
                    
                    Spacer()
                        .frame(maxWidth: .infinity)
                    
                    TextField("Search", text: $searchTerm)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay {
                            if isSearching {
                                HStack {
                                    Spacer()
                                    Button {
                                        self.searchTerm = ""
                                    } label: {
                                        Image(systemName: "multiply.circle.fill")
                                    }
                                    .buttonStyle(.borderless)
                                    .foregroundColor(.secondary)
                                    .padding(.trailing, 4)
                                }
                            }
                        }
                        .frame(width: geometry.maxRelative * 0.2)
                    
                    if isFetching {
                        LottieView(animation: try! .from(data: precompileIncludeData("@/Cider/Resources/CiderSpinner.json")))
                            .playing(loopMode: .loop)
                            .clipShape(Rectangle())
                            .frame(width: 15, height: 15)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 5)
                
                ScrollView {
                    PatchedGeometryReader { geometry in
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], alignment: .center, spacing: 50) {
                            if !isSearching {
                                ForEach(recentlyAddedItems, id: \.id) { item in
                                    MediaPresentable(item: item, maxRelative: geometry.maxRelative.clamped(to: 1000...1100))
                                        .task {
                                            if recentlyAddedItems.last?.id == item.id {
                                                self.isFetching = true
                                                let newItems = await self.mkModal.AM_API.fetchRecentlyAdded(offset: recentlyAddedItems.count)
                                                self.recentlyAddedItems.append(contentsOf: newItems)
                                                self.isFetching = false
                                            }
                                        }
                                }
                            } else {
                                ForEach(searchResultItems, id: \.id) { item in
                                    MediaPresentable(item: item, maxRelative: geometry.maxRelative.clamped(to: 1000...1100))
                                }
                            }
                        }
                        
                        Spacer()
                            .frame(height: 20)
                    }
                }
                .transparentScrollbars()
            }
            .task {
                self.isFetching = true
                self.recentlyAddedItems = await self.mkModal.AM_API.fetchRecentlyAdded()
                self.isFetching = false
            }
            .onChange(of: searchTerm) { searchTerm in
                self.searchResultItems = []
                if searchTerm.isEmpty {
                    self.isSearching = false
                    return
                }
                self.isSearching = true
                
                Debouncer.debounce {
                    Task {
                        self.isFetching = true
                        self.searchResultItems = await self.mkModal.AM_API.searchRecentlyAdded(query: searchTerm)
                        self.isFetching = false
                    }
                }
            }
        }
        .enableInjection()
    }
}

#Preview {
    RecentlyAddedView()
}
