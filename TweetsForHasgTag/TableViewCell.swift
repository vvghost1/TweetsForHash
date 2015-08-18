//
//  TableViewCell.swift
//  TweetsForHasgTag
//
//  Created by Yura Vorontsov on 12.08.15.
//  Copyright (c) 2015 Yura Vorontsov. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    
    var name: String = ""
    var content: String = ""
    var profileImg: UIImage?
    var imageArr: [UIImage]?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        //contentView.autoresizingMask = UIViewAutoresizing.FlexibleHeight
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
