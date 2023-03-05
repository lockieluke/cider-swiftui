//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload
import Throttler
import SDWebImageSwiftUI
import Introspect

struct SearchBar: View {
    
    @ObservedObject private var iO = Inject.observer
    @EnvironmentObject private var searchModal: SearchModal
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var navigationModal: NavigationModal
    
    @FocusState private var isFocused: Bool
    @State private var isHoveringClearButton: Bool = false
    @State private var suggestions: SearchSuggestions?
    @State var fetchSuggestionsTask: Task<Void, Never>?
    
    func updateSearchResults() {
        Task {
            self.searchModal.isLoadingResults = true
            let searchResults = await self.mkModal.AM_API.fetchSearchResults(term: self.searchModal.currentSearchText, types: [.artists, .songs, .albums, .playlists])
            DispatchQueue.main.async {
                self.searchModal.searchResults = searchResults
                self.searchModal.isLoadingResults = false
            }
        }
    }
    
    struct SuggestionView: View {
        
        @EnvironmentObject private var ciderPlayback: CiderPlayback
        @EnvironmentObject private var navigationModal: NavigationModal
        
        @State private var isHovering: Bool = false
        @State private var isClicked: Bool = false
        @State private var isArtworkHovering: Bool = false
        
        @ObservedObject private var iO = Inject.observer
        
        private let displayName: String?
        private let description: String?
        private let artwork: MediaArtwork?
        private let track: MediaTrack?
        private let artist: MediaArtist?
        private let onClick: (() -> Void)?
        
        init(_ suggestion: SearchSuggestions.SearchSuggestion, onClick: (() -> Void)? = nil) {
            var displayName: String?, description: String?
            var artwork: MediaArtwork?
            var track: MediaTrack?
            var artist: MediaArtist?
            if let topResult = suggestion.searchTopResult {
                if case let .artist(mediaArtist) = topResult {
                    displayName = mediaArtist.artistName
                    artwork = mediaArtist.artwork
                    artist = mediaArtist
                } else if case let .track(mediaTrack) = topResult {
                    displayName = mediaTrack.title
                    artwork = mediaTrack.artwork
                    description = mediaTrack.artistName
                    track = mediaTrack
                }
            } else {
                displayName = suggestion.searchTerm?.displayTerm
            }
            
            self.displayName = displayName
            self.description = description
            self.artwork = artwork
            self.artist = artist
            self.track = track
            self.onClick = onClick
        }
        
        var body: some View {
            PatchedGeometryReader { geometry in
                HStack {
                    if let artwork = self.artwork {
                        WebImage(url: artwork.getUrl(width: 100, height: 100))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .cornerRadius(self.artist != nil ? .infinity : 6)
                            .brightness(isArtworkHovering ? -0.5 : 0)
                            .overlay {
                                if isArtworkHovering {
                                    Image(systemName: "play.fill")
                                        .foregroundColor(.white)
                                }
                            }
                            .onHover { isHovering in
                                self.isArtworkHovering = isHovering
                            }
                            .onTapGesture {
                                if let track = self.track {
                                    Task {
                                        await self.ciderPlayback.setQueue(item: .mediaTrack(track))
                                        await self.ciderPlayback.clearAndPlay(item: .mediaTrack(track))
                                    }
                                }
                            }
                    }
                    VStack(alignment: .leading) {
                        if let displayName = self.displayName {
                            Text(displayName)
                        }
                        
                        if let description = self.description {
                            Text(description)
                                .foregroundColor(.gray)
                                .font(.system(size: 10, weight: .light))
                        }
                    }
                    Spacer()
                }
                .frame(width: abs(geometry.size.width - 15))
                .padding(.vertical, 5)
                .padding(.leading, 10)
            }
            .background {
                RoundedRectangle(cornerRadius: 5)
                    .fill(isHovering ? Color("SecondaryColour") : Color.clear)
                    .brightness(isClicked ? -0.5 : 0)
            }
            .onHover { isHovering in
                self.isHovering = isHovering
            }
            .onTapGesture {
                if let artist = self.artist {
                    self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .artistViewParams(ArtistViewParams(artist: artist))))
                }
                self.onClick?()
            }
            .modifier(PressActions(onEvent: { isPressed in
                self.isClicked = isPressed
            }))
            .padding(.vertical, 2)
            .padding(.horizontal, 3)
            .enableInjection()
        }
        
    }
    
    var suggestionsView: some View {
        VStack(alignment: .center, spacing: 0) {
            if let searchSuggestions = self.suggestions?.searchSuggestions {
                ForEach(searchSuggestions, id: \.id) { searchSuggestion in
                    SuggestionView(searchSuggestion, onClick: {
                        self.isFocused = false
                        if let searchTerm = searchSuggestion.searchTerm {
                            self.searchModal.currentSearchText = searchTerm.displayTerm
                            self.searchModal.shouldDisplaySearchPage = true
                            self.updateSearchResults()
                        }
                    })
                    .environmentObject(ciderPlayback)
                    .environmentObject(navigationModal)
                }
            }
        }
        .padding(.vertical, 5)
        .enableInjection()
    }
    
    var clearSearchView: some View {
        Group {
            if !self.searchModal.currentSearchText.isEmpty {
                Image(systemName: "xmark")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.secondary)
                    .background {
                        if isHoveringClearButton {
                            Circle()
                                .fill(.gray)
                                .scaleEffect(1.5)
                        }
                    }
                    .contentShape(Circle())
                    .onHover { isHovering in
                        self.isHoveringClearButton = isHovering
                    }
                    .onTapGesture {
                        self.searchModal.currentSearchText = ""
                    }
                    .padding(.trailing, 20)
            }
        }
    }
    
    var body: some View {
        PatchedGeometryReader { geometry in
            let searchBarWidth = geometry.size.width * 0.2
            
            TextField("Search", text: $searchModal.currentSearchText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 10)
                .frame(width: searchBarWidth, height: 30)
                .contentShape(Rectangle())
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color("SecondaryColour"))
                        .onTapGesture {
                            self.isFocused = true
                        }
                }
                .focused($isFocused)
                .onHover { isHovered in
                    if isHovered {
                        NSCursor.iBeam.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .onChange(of: isFocused) { newIsFocused in
                    self.searchModal.isFocused = newIsFocused
                }
                .onAppear {
                    self.isFocused = true
                }
                .padding(.horizontal, 10)
                .overlay(
                    Group {
                        if isFocused && !searchModal.currentSearchText.isEmpty {
                            suggestionsView
                        }
                    }
                        .frame(width: searchBarWidth)
                        .background(VisualEffectBackground(material: .sheet))
                        .cornerRadius(10)
                        .shadow(radius: 3)
                        .offset(y: 45)
                        .onReceive(self.searchModal.$currentSearchText.debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)) { newCurrentSearchText in
                            guard !newCurrentSearchText.isEmpty else {
                                self.searchModal.shouldDisplaySearchPage = false
                                return
                            }
                            Debouncer.debounce(delay: .milliseconds(200), shouldRunImmediately: true) {
                                self.suggestions?.searchSuggestions = []
                                self.fetchSuggestionsTask = Task {
                                    if Task.isCancelled {
                                        return
                                    }
                                    self.suggestions = try? await self.mkModal.AM_API.fetchSearchSuggestions(term: newCurrentSearchText)
                                }
                            }
                        }
                        .onDisappear {
                            self.fetchSuggestionsTask?.cancel()
                        }
                    , alignment: .top)
                .overlay(clearSearchView, alignment: .trailing)
                .onSubmit {
                    self.isFocused = false
                    self.searchModal.shouldDisplaySearchPage = true
                    self.updateSearchResults()
                    
                }
        }
        .enableInjection()
    }
}

struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar()
            .environmentObject(SearchModal())
    }
}
