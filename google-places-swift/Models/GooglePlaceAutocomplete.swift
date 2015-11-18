//
//  GoogleAutocompletePlace.swift
//  google-places-swift
//
//  Created by WAYNE SMALL on 11/7/15.
//  Copyright © 2015 Waynemystir. All rights reserved.
//

import UIKit

class GooglePlaceAutocomplete: GooglePlace, NetworkResponseDelegate {
    
    var responseRecords:Any?
    
    required convenience init?(json: AnyObject?) {
        self.init(placeId: GooglePlace.kGooglePlaceCollectionId, placeDescription: GooglePlace.kGooglePlaceCollectionDesc)
        
        var preds = [GooglePlaceAutocomplete]()
        
        if let js = json as? NSDictionary, predictions = js["predictions"] as? NSArray {
            for pr in predictions {
                if let gpa = GooglePlaceAutocomplete(dictionary: pr as? NSDictionary) { preds.append(gpa) }
            }
        }
        
        responseRecords = preds
    }
    
    required convenience init?(dictionary: NSDictionary?) {
        guard let d = dictionary,
            let pi = d["place_id"] as? String,
            let pd = d["description"] as? String
            else { return nil }
        
        self.init(placeId: pi, placeDescription: pd)
    }

}
