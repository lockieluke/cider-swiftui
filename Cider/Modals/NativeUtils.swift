//
//  NativeUtils.swift
//  Cider
//
//  Created by Sherlock LUK on 01/04/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation

class NativeUtilsWrapper: ObservableObject {
    
    let nativeUtils: NativeUtils

    init () {
        self.nativeUtils = NativeUtils()
        
        initCXXNativeUtils()
        initLogViewer()
    }
}
