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

struct SidebarItem: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @State private var isHovering = false
    @State private var isClicking = false
    
    @EnvironmentObject private var navigationModal: NavigationModal
    
    private let title: String
    private let icon: SidebarItemIcon
    private let stackType: RootNavigationType
    
    enum SidebarItemIcon: String {
        case Home = "house",
        ListenNow = "play.circle",
        Browse = "rectangle.grid.2x2",
        Radio = "dot.radiowaves.left.and.right",
        RecentlyAdded = "clock",
        Songs = "music.note",
        Albums = "square.stack",
        Artists = "music.mic"
    }
    
    init(_ title: String, icon: SidebarItemIcon, stackType: RootNavigationType? = nil) {
        self.title = title
        self.icon = icon
        self.stackType = stackType ?? RootNavigationType(rawValue: title) ?? .AnyView
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
                .fill(navigationModal.currentRootStack == stackType ? Color.secondary.opacity(0.5) : isHovering ? Color.secondary.opacity(isClicking ? 0.5 : 0.3) : Color.clear)
                .animation(.easeInOut, value: isClicking)
        }
        .onHover { isHovering in
            self.isHovering = isHovering
        }
        .onTapGesture {
            withAnimation(.spring()) {
                self.navigationModal.showSidebar = false
            }
            self.navigationModal.currentRootStack = self.stackType
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
    
    @State private var showingAMSection = true
    
    var body: some View {
        SidePane(direction: .Left, content: {
            List {
                SidebarSection("Apple Music") {
                    SidebarItem("Home", icon: .Home)
                    SidebarItem("Listen Now", icon: .ListenNow, stackType: .ListenNow)
                    SidebarItem("Browse", icon: .Browse)
                    SidebarItem("Radio", icon: .Radio)
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
                    
                }
                .foregroundStyle(.white)
            }
            .introspect(.list, on: .macOS(.v10_15, .v11, .v12, .v13, .v14)) { list in
                list.backgroundColor = .clear
            }
            .listStyle(.sidebar)
        }, headerChildren: {
            
        })
        .enableInjection()
    }
}

struct SidebarPane_Previews: PreviewProvider {
    static var previews: some View {
        SidebarPane()
    }
}
