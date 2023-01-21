//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI

struct PatchedGeometryReaderSize: PreferenceKey {
    
    static var defaultValue = CGSize()
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
    
}

struct PatchedGeometryProxy {
    
    var size: CGSize = .zero
    var minRelative: CGFloat = .zero
    
}

struct PatchedGeometryReader<Content: View>: View {
    
    @ViewBuilder var content: (PatchedGeometryProxy) -> Content
    
    @State private var geometryProxy = PatchedGeometryProxy()
    
    init(@ViewBuilder content: @escaping (PatchedGeometryProxy) -> Content) {
        self.content = content
    }
    
    var body: some View {
        Group {
            GeometryReader { geometry in
                Color.clear
                    .onChange(of: geometry.size) { newSize in
                        self.geometryProxy = PatchedGeometryProxy(size: newSize, minRelative: min(newSize.width, newSize.height))
                    }
                    .onAppear {
                        self.geometryProxy = PatchedGeometryProxy(size: geometry.size, minRelative: min(geometry.size.width, geometry.size.height))
                    }
            }
            
            content(self.geometryProxy)
        }
    }
}
