//
//  SiderbarPane.swift
//  Cider
//
//  Created by Sherlock LUK on 14/07/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import Introspect
import Inject
import Defaults

fileprivate struct UpdateNowButton: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var navigationModal: NavigationModal
    
    @State private var isHovering: Bool = false
    @State private var isClicking: Bool = false
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemSymbol: .arrowDownAppFill)
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 3) {
                Text("Ready to update")
                    .bold()
                Text("New update available")
                    .font(.system(size: 10))
            }
        }
        .padding()
        .background(Color("PrimaryColour").brightness(isHovering ? (isClicking ? -0.1 : 0) : 0.1))
        .animation(.none, value: isHovering)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 10)
        .onHover { isHovering in
            self.isHovering = isHovering
        }
        .onTapGesture {
            UpdateHelper.shared.updateInitiaited = true
            self.navigationModal.isAboutViewPresent = true
        }
        .gesture(DragGesture(minimumDistance: 0).onChanged { _ in
            self.isClicking = true
        }.onEnded { _ in
            self.isClicking = false
        })
        .enableInjection()
    }
}

fileprivate struct SidebarItem: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @State private var isHovering = false
    @State private var isClicking = false
    @State private var highlightingAnyway = false
    
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var mkModal: MKModal
    
    @Environment(\.colorScheme) var colorScheme
    
    private let title: String
    private let icon: SidebarItemIcon
    private let stackType: RootNavigationType
    private let playlistID: String?
    
    enum SidebarItemIcon: String {
        case Home = "house",
             ListenNow = "play.circle",
             Browse = "rectangle.grid.2x2",
             Radio = "dot.radiowaves.left.and.right",
             RecentlyAdded = "clock",
             Songs = "music.note",
             Albums = "square.stack",
             Artists = "music.mic",
             Playlist = "list.bullet"
    }
    
    init(_ title: String, icon: SidebarItemIcon, stackType: RootNavigationType? = nil, playlistID: String? = nil) {
        self.title = title
        self.icon = icon
        self.stackType = stackType ?? .AnyView
        self.playlistID = playlistID
    }
    
    var shouldHighlight: Bool {
        if self.isHovering || self.highlightingAnyway {
            return true
        }
        
        if self.playlistID != nil {
            return navigationModal.viewsStack.last?.params?.value == self.playlistID
        }
        
        if self.stackType != .AnyView {
            return navigationModal.currentRootStack == self.stackType
        }
        
        return false
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon.rawValue)
                .font(.body)
                .frame(width: 15, height: 15)
                .aspectRatio(contentMode: .fill)
                .foregroundStyle(.pink)
            
            Text(title)
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
        .padding([.horizontal, .vertical], 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(shouldHighlight ?  Color.secondary.opacity(0.5) : Color.clear)
                .animation(.easeInOut, value: isClicking)
        }
        .onHover { isHovering in
            self.isHovering = isHovering
        }
        .onTapGesture {
            self.highlightingAnyway = true
            if playlistID == nil {
                self.navigationModal.currentRootStack = self.stackType
                self.highlightingAnyway = false
            } else {
                Task {
                    var playlist: MediaPlaylist?
                    do {
                        playlist = try await self.mkModal.AM_API.fetchPlaylist(id: playlistID ?? "")
                    } catch {}
                    
                    if playlist != nil {
                        self.navigationModal.currentRootStack = .Playlist
                        self.highlightingAnyway = false
                        self.navigationModal.replaceCurrentViewStack(NavigationStack(isPresent: true, params: .detailedViewParams(DetailedViewParams(item: .mediaPlaylist(playlist!), geometryMatching: nil, originalSize: CGSize(width: 1, height: 1), coverKind: "bb"))))
                    }
                }
            }
        }
        .modifier(PressActions(onEvent: { isClicking in
            self.isClicking = isClicking
        }))
        .enableInjection()
    }
    
}

fileprivate struct SidebarSection<Content: View>: View {
    
    @ViewBuilder var content: () -> Content
    
    @ObservedObject private var iO = Inject.observer
    
    @Environment(\.colorScheme) var colorScheme
    
    private let title: String
    
    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        Section(title) {
            VStack(spacing: 2) {
                content()
            }
        }
        .foregroundStyle(.gray)
    }
    
}

struct SidebarPane: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var mkModal: MKModal
    
    @State private var showingAMSection = true
    @State private var allPlaylistsData: [MediaPlaylist] = []
    @State private var loadedSavedWidth = false
    
    @StateObject private var updateHelper = UpdateHelper.shared
    
    @Default(.sidebarWidth) private var sidebarWidth
    
    var body: some View {
        List {
            if updateHelper.updateNeeded && !ProcessInfo.processInfo.arguments.contains("-disable-update-checks") {
                HStack {
                    Spacer()
                    UpdateNowButton()
                    Spacer()
                }
            }
            
            if mkModal.isAuthorised {
                Group {
                    SidebarSection("Apple Music") {
                        SidebarItem("Home", icon: .Home, stackType: .Home)
                        SidebarItem("Listen Now", icon: .ListenNow, stackType: .ListenNow)
                        SidebarItem("Browse", icon: .Browse, stackType: .Browse)
                        SidebarItem("Radio", icon: .Radio, stackType: .Radio)
                    }
                    
                    SidebarSection("Library") {
                        SidebarItem("Recently Added", icon: .RecentlyAdded, stackType: .RecentlyAdded)
                        SidebarItem("Songs", icon: .Songs, stackType: .Songs)
                        SidebarItem("Albums", icon: .Albums)
                        SidebarItem("Artists", icon: .Artists)
                    }
                    
                    SidebarSection("Apple Music Playlists") {
                        
                    }
                    
                    SidebarSection("Playlists") {
                        ForEach(allPlaylistsData) { playlist in
                            SidebarItem(playlist.title, icon: .Playlist, stackType: .Playlist, playlistID: playlist.id)
                        }
                    }
                }
                .task {
                    self.allPlaylistsData = await mkModal.AM_API.fetchPlaylists()
                }
                .animation(.none)
            }
        }
        .introspect(.list, on: .macOS(.v10_15, .v11, .v12, .v13, .v14)) { list in
            list.backgroundColor = .clear
        }
        .frame(minWidth: 250, maxWidth: 400)
        // restoring sidebar width here
        .frame(width: loadedSavedWidth ? nil : Defaults[.sidebarWidth])
        .if(!navigationModal.showSidebar) { view in
            view
                .frame(width: .zero)
                .onAppear {
                    self.loadedSavedWidth = false
                }
        }
        .onChange(of: navigationModal.showSidebar) { showSidebar in
            // hacky way to restore sidebar width but still allow adjusting
            if showSidebar {
                self.loadedSavedWidth = false
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
                    self.loadedSavedWidth = true
                }
            }
        }
        .listStyle(.sidebar)
        .enableInjection()
    }

}

struct SidebarPane_Previews: PreviewProvider {
    static var previews: some View {
        SidebarPane()
    }
}
