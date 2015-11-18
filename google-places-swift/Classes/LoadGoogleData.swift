//
//  LoadGoogleData.swift
//  google-places-swift
//
//  Created by WAYNE SMALL on 11/7/15.
//  Copyright © 2015 Waynemystir. All rights reserved.
//

import UIKit

public enum SerializationError: ErrorType { case InvalidObject, InvalidRequest, RequestDenied, EncodingError }

enum GOOGLE_DATA: Int { case AUTOCOMPLETE, PLACE_DETAILS }

protocol LoadGoogleDataDelegate {
    func loadedData(dataType: GOOGLE_DATA, googleObject: NetworkResponseDelegate)
    func requestTimedOut(dataType: GOOGLE_DATA)
    func requestFailedOffline(dataType: GOOGLE_DATA)
    func requestFailed(dataType: GOOGLE_DATA)
}

class LoadGoogleData: NSObject {
    
    static let manager = LoadGoogleData()
    private static let kGoogleApiKey = "Your API Key"
    private static let kAutoCompleteBaseUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
    private static let kPlaceDetailsBaseUrl = "https://maps.googleapis.com/maps/api/place/details/json"
    
    var googleDelegate:LoadGoogleDataDelegate?
    
    class func autocomplete(autocompleteText: String) -> NSURLSessionTask {
        let urlStr = "\(kAutoCompleteBaseUrl)?input=\(autocompleteText)&key=\(kGoogleApiKey)"
        return dataTask(urlStr, dataType: GOOGLE_DATA.AUTOCOMPLETE, classT: GooglePlaceAutocomplete.self)
    }
    
    class func loadPlaceDetails(placeId: String) -> NSURLSessionTask {
        let urlStr = "\(kPlaceDetailsBaseUrl)?placeid=\(placeId)&key=\(kGoogleApiKey)"
        return dataTask(urlStr, dataType: GOOGLE_DATA.PLACE_DETAILS, classT: GooglePlaceDetails.self)
    }
    
    private class func dataTask(var url: String, dataType: GOOGLE_DATA, classT:NetworkResponseDelegate.Type) -> NSURLSessionTask {
        url = url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.timeoutInterval = 30
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
            if handleError(error, dataType: dataType) || handleResponse(response, dataType: dataType) { return };
            guard let d = data else { return mq( { manager.googleDelegate?.requestFailed(dataType) } ) }
            
            let json:AnyObject?
            do {
                json = try NSJSONSerialization.JSONObjectWithData(d, options: [])
                
                guard let obj = json where NSJSONSerialization.isValidJSONObject(obj) else {
                    throw SerializationError.InvalidObject
                }
                
                if let status = json?["status"] as? String where status == "INVALID_REQUEST" {
                    throw SerializationError.InvalidRequest
                }
                
                if let status = json?["status"] as? String where status == "REQUEST_DENIED" {
                    throw SerializationError.RequestDenied
                }
            }
            catch let error as NSError {
                print("\(__FUNCTION__)  ERROR trying to deserialize JSON data:\(error)")
                mq( { manager.googleDelegate?.requestFailed(dataType) } )
                return
            }
            
            if let nrd = classT.init(json: json) { mq( { manager.googleDelegate?.loadedData(dataType, googleObject: nrd) } ) }
        }
        task.resume()
        return task
    }
    
    private class func handleError(error: NSError?, dataType: GOOGLE_DATA) -> Bool {
        guard let err = error else { return false }
        switch(err.code) {
        case NSURLErrorCancelled: break
        case NSURLErrorTimedOut: mq( { manager.googleDelegate?.requestTimedOut(dataType) } )
        case NSURLErrorNotConnectedToInternet: mq( { manager.googleDelegate?.requestFailedOffline(dataType) } )
        default: mq( { manager.googleDelegate?.requestFailed(dataType) } )
        }
        
        return true
    }
    
    private class func handleResponse(response: NSURLResponse?, dataType: GOOGLE_DATA) -> Bool {
        if let resp = response as? NSHTTPURLResponse where resp.statusCode == 200 { return false }
        mq( { manager.googleDelegate?.requestFailed(dataType) } )
        return true
    }
    
    private class func mq(block: () -> Void) { NSOperationQueue.mainQueue().addOperationWithBlock(block) }
    
}
