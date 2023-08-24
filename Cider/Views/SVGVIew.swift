//
//  SVGVIew.swift
//  Cider
//
//  Created by Sherlock LUK on 20/08/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftUI
import SVGKit

struct SVGKFastImageViewSUI: NSViewRepresentable {
    
    private var url: URL
    @Binding private var size: CGSize
    
    init(url: URL, size: Binding<CGSize>) {
        self.url = url
        self._size = size
    }
    
    func makeNSView(context: Context) -> SVGKFastImageView {
        let svgImage = SVGKImage(contentsOf: self.url)
        return SVGKFastImageView(svgkImage: svgImage ?? SVGKImage())
    }
    
    func updateNSView(_ nsView: SVGKFastImageView, context: Context) {
        nsView.image.size = self.size
    }
    
}

