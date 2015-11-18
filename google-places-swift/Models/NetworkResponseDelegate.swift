//
//  NetworkResponseDelegate.swift
//  google-places-swift
//
//  Created by WAYNE SMALL on 11/14/15.
//  Copyright © 2015 Waynemystir. All rights reserved.
//

import Foundation

protocol NetworkResponseDelegate {
    
    var responseRecords:Any? { get set }
    
    init?(json: AnyObject?)
    
}
