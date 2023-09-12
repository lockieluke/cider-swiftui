//
//  EditorialArtwork.swift
//  Cider
//
//  Created by Monochromish on 12/09/23.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyJSON

struct EditorialArtwork {
    let staticDetailTall: MediaArtwork
    let subscriptionHero: MediaArtwork
    let staticDetailSquare: MediaArtwork
    let storeFlowcase: MediaArtwork

    init(data: JSON) {
        self.staticDetailTall = MediaArtwork(data: data["staticDetailTall"])
        self.subscriptionHero = MediaArtwork(data: data["subscriptionHero"])
        self.staticDetailSquare = MediaArtwork(data: data["staticDetailSquare"])
        self.storeFlowcase = MediaArtwork(data: data["storeFlowcase"])
    }
}
