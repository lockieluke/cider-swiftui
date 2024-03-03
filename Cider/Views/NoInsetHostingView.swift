//
//  NoInsetHostingView.swift
//  Cider
//
//  Created by Sherlock LUK on 03/03/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import Foundation
import SwiftUI

class NoInsetHostingView<V>: NSHostingView<V> where V: View {
    
    override var safeAreaInsets: NSEdgeInsets {
        return .init()
    }
    
}
