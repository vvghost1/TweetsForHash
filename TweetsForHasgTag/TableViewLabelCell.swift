//
//  TableViewLabelCell.swift
//  TweetsForHasgTag
//
//  Created by Yura Vorontsov on 16.08.15.
//  Copyright (c) 2015 Yura Vorontsov. All rights reserved.
//

import UIKit

class TableViewLabelCell: TableViewCell {
    
    override var name: String{didSet{nameLabel.text = name}}
    override var content: String{didSet{contentLabel.text = content}}
    override var profileImg: UIImage?{didSet{profileImgLabel.image = profileImg}}
    
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var profileImgLabel: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        profileImgLabel.layer.cornerRadius = CGFloat(4.0)
        profileImgLabel.clipsToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
