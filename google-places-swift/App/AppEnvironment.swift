//
//  AppEnvironment.swift
//  google-places-swift
//
//  Created by WAYNE SMALL on 11/16/15.
//  Copyright © 2015 Waynemystir. All rights reserved.
//

import UIKit

class AppEnvironment: NSObject {
    
    static let kMetersPerMile = 1609.344
    
    class func kGpsCacheDir() -> String? {
        var path = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
        path += "/\(NSBundle.mainBundle().bundleIdentifier!)"
        
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            guard let _ = try? NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil) else { return nil }
        }
        
        return path
    }
    
    class func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

}
