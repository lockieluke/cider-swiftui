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

struct SidebarItem: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @State private var isHovering = false
    @State private var isClicking = false
    
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var mkModal: MKModal
    
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
    
    func shouldHighlight() -> Bool {
        if self.isHovering {
            return true
        }
        
        if self.stackType != .AnyView {
            return navigationModal.currentRootStack == self.stackType
        }
        
        if self.playlistID != nil {
            return navigationModal.viewsStack.last?.params?.value == self.playlistID
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
        }
        .padding([.horizontal, .vertical], 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(shouldHighlight() ?  Color.secondary.opacity(0.5) : Color.clear)
                .animation(.easeInOut, value: isClicking)
        }
        .onHover { isHovering in
            self.isHovering = isHovering
        }
        .onTapGesture {
            withAnimation(.spring()) {
                self.navigationModal.showSidebar = false
            }
            if playlistID == nil {
                self.navigationModal.currentRootStack = self.stackType
                self.navigationModal.resetToRoot()
            } else {
                Task {
                    var playlist: MediaPlaylist?
                    do {
                        playlist = try await self.mkModal.AM_API.fetchPlaylist(id: playlistID ?? "")
                    } catch {}
                    
                    if playlist != nil {
                        self.navigationModal.showSidebar = false
                        self.navigationModal.currentRootStack = .AnyView
                        self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .detailedViewParams(DetailedViewParams(item: .mediaPlaylist(playlist!), geometryMatching: nil, originalSize: CGSize(width: 1, height: 1), coverKind: "bb"))))
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

struct SidebarSection<Content: View>: View {
    
    @ViewBuilder var content: () -> Content
    
    @ObservedObject private var iO = Inject.observer
    
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
        .foregroundStyle(.white)
    }
    
}

struct SidebarPane: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var mkModal: MKModal
    
    @State private var showingAMSection = true
    @State private var allPlaylistsData: [MediaPlaylist] = []
    @State private var loadedSavedWidth = false
    @State private var sidebarWidth: CGFloat = 250.0
    
    var body: some View {
        List {
            if mkModal.isAuthorised {
                Group {
                    SidebarSection("Apple Music") {
                        SidebarItem("Home", icon: .Home, stackType: .Home)
                        SidebarItem("Listen Now", icon: .ListenNow, stackType: .ListenNow)
                        SidebarItem("Browse", icon: .Browse, stackType: .Browse)
                        SidebarItem("Radio", icon: .Radio, stackType: .Radio)
                    }
                    
                    Section("Library") {
                        SidebarItem("Recently Added", icon: .RecentlyAdded)
                        SidebarItem("Songs", icon: .Songs)
                        SidebarItem("Albums", icon: .Albums)
                        SidebarItem("Artists", icon: .Artists)
                    }
                    .foregroundStyle(.white)
                    
                    Section("Apple Music Playlists") {
                        
                    }
                    .foregroundStyle(.white)
                    
                    Section("Playlists") {
                        ForEach(allPlaylistsData) { playlist in
                            SidebarItem(playlist.title, icon: .Playlist, playlistID: playlist.id)
                        }
                    }
                    .foregroundStyle(.white)
                }
                .task {
                    await fetchPlaylists()
                }
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
        .onAppear {
            if Defaults[.sidebarWidth] == 0 {
                Defaults[.sidebarWidth] = 250
            }
        }
        .listStyle(.sidebar)
        .enableInjection()
    }
    
    private func fetchPlaylists() async {
        self.allPlaylistsData = await mkModal.AM_API.fetchPlaylists()
    }
}

struct SidebarPane_Previews: PreviewProvider {
    static var previews: some View {
        SidebarPane()
    }
}
