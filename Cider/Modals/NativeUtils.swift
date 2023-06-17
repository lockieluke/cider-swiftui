//
//  NativeUtils.swift
//  Cider
//
//  Created by Sherlock LUK on 01/04/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation

private let _nativeUtilsGlobal = NativeUtils()

class NativeUtilsWrapper: ObservableObject {
    
    let nativeUtils: NativeUtils
    static let nativeUtilsGlobal = _nativeUtilsGlobal
    

    init () {
        self.nativeUtils = _nativeUtilsGlobal
        
        initCXXNativeUtils()
        initLogViewer()
    }
}
