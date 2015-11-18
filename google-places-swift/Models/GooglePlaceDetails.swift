//
//  GooglePlace.swift
//  google-places-swift
//
//  Created by WAYNE SMALL on 11/7/15.
//  Copyright © 2015 Waynemystir. All rights reserved.
//

import UIKit
import MapKit

class GooglePlaceDetails: GooglePlace, NetworkResponseDelegate, NSCoding {
    
    private static let kKeyFormattedAddress = "formattedAddress"
    private static let kKeyPlacePlaceId = "placeId"
    private static let kKeyPlaceLatitude = "latitude"
    private static let kKeyPlaceLongitude = "longitude"
    private static let kKeyZoomRadius = "zoomRadius"
    
    var latitude: Double?
    var longitude: Double?
    var zoomRadius: Double?
    
    // MARK: NetworkResponseDelegate
    
    var responseRecords: Any?
    
    required convenience init?(json: AnyObject?) {
        
        guard let result = json?["result"] as? NSDictionary,
            let pd = result["formatted_address"] as? String,
            let pi = result["place_id"] as? String
            else { return nil }
        
        self.init(placeId: pi, placeDescription: pd)
        
        if let geometry = result["geometry"] as? NSDictionary {
            if let location = geometry["location"] as? NSDictionary {
                latitude = location["lat"] as? Double
                longitude = location["lng"] as? Double
            }
            zoomRadius = viewportToMilesRadius(geometry["viewport"] as? NSDictionary)
        }
        
        // TODO: handle nil values for lat, long, zoom radius more gracefully.
        // Or should I make the lat, long, zr immutable?
        // In particular, the viewport and zoom radius will often be missing
        // from the Google JSON response.
        // For now, I set the location to St Barts.
        
        latitude = latitude ?? 17.896564
        longitude = longitude ?? -62.852331
        zoomRadius = zoomRadius ?? 3.0
    }
    
    private func viewportToMilesRadius(viewport: NSDictionary?) -> Double {
        guard let vp = viewport,
            let northeast = vp["northeast"],
            let southwest = vp["southwest"],
            let neLat = northeast["lat"] as? Double,
            let neLng = northeast["lng"] as? Double,
            let swLat = southwest["lat"] as? Double,
            let swLng = southwest["lng"] as? Double
            else { return 3.0 }
        
        let neLoc = CLLocation(latitude: neLat, longitude: neLng)
        let swLoc = CLLocation(latitude: swLat, longitude: swLng)
        
        return swLoc.distanceFromLocation(neLoc) / AppEnvironment.kMetersPerMile;
    }
    
    // MARK: NSCoding
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        guard let pi = aDecoder.decodeObjectForKey(GooglePlaceDetails.kKeyPlacePlaceId) as? String,
            let pd = aDecoder.decodeObjectForKey(GooglePlaceDetails.kKeyFormattedAddress) as? String
            else { return nil }
        
        self.init(placeId: pi, placeDescription: pd)
        
        latitude = aDecoder.decodeDoubleForKey(GooglePlaceDetails.kKeyPlaceLatitude)
        longitude = aDecoder.decodeDoubleForKey(GooglePlaceDetails.kKeyPlaceLongitude)
        zoomRadius = aDecoder.decodeDoubleForKey(GooglePlaceDetails.kKeyZoomRadius)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.placeDescription, forKey: GooglePlaceDetails.kKeyFormattedAddress)
        aCoder.encodeObject(self.placeId, forKey: GooglePlaceDetails.kKeyPlacePlaceId)
        aCoder.encodeDouble(self.latitude ?? 17.896564, forKey: GooglePlaceDetails.kKeyPlaceLatitude)
        aCoder.encodeDouble(self.longitude ?? -62.852331, forKey: GooglePlaceDetails.kKeyPlaceLongitude)
        aCoder.encodeDouble(self.zoomRadius ?? 3.0, forKey: GooglePlaceDetails.kKeyZoomRadius)
    }
    
    // MARK: Memberwise convenience
    
    required convenience init(placeId: String,
        placeDescription: String,
        latitude: Double?,
        longitude: Double?,
        zoomRadius: Double?) {
            
        self.init(placeId: placeId, placeDescription: placeDescription)
        self.latitude = latitude;
        self.longitude = longitude
        self.zoomRadius = zoomRadius
    }

}
