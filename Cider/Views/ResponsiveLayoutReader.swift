//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI

struct ResponsiveLayoutProperties {
    
    var size: CGSize = .zero
    var ratio: CGFloat = .zero
    
}

struct ResponsiveLayoutReader<Content: View>: View {
    
    @ViewBuilder var content: (_ windowProps: ResponsiveLayoutProperties) -> Content
    
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @State private var windowProps = ResponsiveLayoutProperties()
    
    init(@ViewBuilder content: @escaping (_ windowProps: ResponsiveLayoutProperties) -> Content) {
        self.content = content
    }
    
    var body: some View {
        content(windowProps)
            .onChange(of: appWindowModal.windowSize) { newWindowSize in
                self.windowProps.size = newWindowSize
                self.windowProps.ratio = newWindowSize.width / newWindowSize.height
            }
            .onAppear {
                self.windowProps.size = self.appWindowModal.windowSize
                self.windowProps.ratio = self.appWindowModal.windowSize.width / self.appWindowModal.windowSize.height
            }
    }
}
