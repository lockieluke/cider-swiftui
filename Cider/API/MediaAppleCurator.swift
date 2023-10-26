//
//  MediaAppleCurator.swift
//  Cider
//
//  Created by Sherlock LUK on 26/10/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyJSON

class MediaAppleCurator {
    
    let id: String
    let title: String
    let shortTitle: String
    let hostName: String
    let artwork: MediaArtwork
    let editorialArtwork: MediaEditorialArtwork
    let editorialNotes: MediaEditorialNotes
    
    init(data: JSON) {
        self.id = data["id"].stringValue
        
        let attributes = data["attributes"]
        self.title = attributes["name"].stringValue
        self.shortTitle = attributes["shortName"].stringValue
        self.hostName = attributes["showHostName"].stringValue
        self.artwork = MediaArtwork(data: attributes["artwork"])
        self.editorialArtwork = MediaEditorialArtwork(data: attributes["editorialArtwork"])
        self.editorialNotes = MediaEditorialNotes(data: attributes["editorialNotes"])
    }
    
}
