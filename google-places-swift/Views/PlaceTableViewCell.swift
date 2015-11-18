//
//  PlaceTableViewCell.swift
//  google-places-swift
//
//  Created by WAYNE SMALL on 11/8/15.
//  Copyright © 2015 Waynemystir. All rights reserved.
//

import UIKit

class PlaceTableViewCell: UITableViewCell {

    @IBOutlet weak var placeDescription: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
