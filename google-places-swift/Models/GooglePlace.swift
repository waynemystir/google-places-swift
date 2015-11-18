//
//  GooglePlace.swift
//  google-places-swift
//
//  Created by WAYNE SMALL on 11/14/15.
//  Copyright © 2015 Waynemystir. All rights reserved.
//

import Foundation

class GooglePlace: NSObject {
    
    internal static let kGooglePlaceCollectionId = "kGooglePlaceCollectionId"
    internal static let kGooglePlaceCollectionDesc = "kGooglePlaceCollectionDesc"
    
    let placeId: String
    let placeDescription: String
    
    init(placeId: String, placeDescription: String) {
        self.placeId = placeId
        self.placeDescription = placeDescription
    }

}
