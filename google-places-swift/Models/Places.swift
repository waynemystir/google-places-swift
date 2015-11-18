//
//  Places.swift
//  google-places-swift
//
//  Created by WAYNE SMALL on 11/8/15.
//  Copyright © 2015 Waynemystir. All rights reserved.
//

import UIKit

final class Places: NSObject, NSCoding {
    
    private static let kMaxNumbOfSavedPlaces = 20;
    private static let kGooglePlaceCurrentLocationId = "kGooglePlaceCurrentLocationId";
    private static let kKeyPlacesArray = "kKeyPlacesArray";
    
    // MARK: Stored properties
    
    class var manager: Places {
        struct Static {
            static var instance: Places?
            static var token: dispatch_once_t = 0
        }
        dispatch_once(&Static.token) {
            if let p = pathForPlaces(), m = NSKeyedUnarchiver.unarchiveObjectWithFile(p) as? Places { Static.instance = m }
            
            if Static.instance == nil {
                let gp = GooglePlaceDetails(placeId: Places.kGooglePlaceCurrentLocationId, placeDescription: "Current Location", latitude: 0.0, longitude: 0.0, zoomRadius: 20.0)
                Static.instance = Places(savedPlaces: [gp])
                Static.instance?.save()
            }
        }
        return Static.instance!
    }
    
    private(set) var savedPlaces: [GooglePlaceDetails]
    var selectedPlace: GooglePlaceDetails {
        get { return self.currentLocationIsSelectedPlace ? savedPlaces[0] : savedPlaces[1] }
        set {
            if (newValue.placeId == Places.kGooglePlaceCurrentLocationId) {
                currentLocationIsSelectedPlace = true
                return
            }
            currentLocationIsSelectedPlace = false
            
            for (index, value) in self.savedPlaces.enumerate() {
                if(value.placeDescription == newValue.placeDescription || value.placeId == newValue.placeId) {
                        self.savedPlaces.removeAtIndex(index)
                }
            }
            
            self.savedPlaces.insert(newValue, atIndex: 1)
            while (self.savedPlaces.count - Places.kMaxNumbOfSavedPlaces > 0) {
                self.savedPlaces.removeAtIndex(self.savedPlaces.count - 1)
            }
            self.save()
        }
    }
    var currentLocationIsSelectedPlace: Bool = true
    
    // MARK: Designated
    
    init(savedPlaces: [GooglePlaceDetails]) { self.savedPlaces = savedPlaces }
    
    // MARK: NSCoding
    
    convenience init?(coder aDecoder: NSCoder) {
        guard let savedPlaces = aDecoder.decodeObjectForKey(Places.kKeyPlacesArray) as? [GooglePlaceDetails]
            else { return nil }
        
        self.init(savedPlaces: savedPlaces)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(savedPlaces, forKey: Places.kKeyPlacesArray)
    }
    
    // MARK: Storing methods
    
    func save() {
        if let path = Places.pathForPlaces() { NSKeyedArchiver.archiveRootObject(self, toFile: path) }
    }
    
    class func pathForPlaces() -> String? {
        if let cache = AppEnvironment.kGpsCacheDir() { return cache + "/places" } else { return nil }
    }

}
