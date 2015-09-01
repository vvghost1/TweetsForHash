//
//  TableViewImageCell.swift
//  TweetsForHasgTag
//
//  Created by Yura Vorontsov on 12.08.15.
//  Copyright (c) 2015 Yura Vorontsov. All rights reserved.
//

import UIKit

class TableViewImageCell: TableViewCell
{
    override var name: String{didSet{nameLabel.text = name}}
    override var content: String{didSet{contentLabel.text = content}}
    override var profileImg: UIImage?{didSet{profileImgLabel.image = profileImg}}
    override var imageArr: [UIImage]?
    {
        didSet
        {
            imageLabel.image = nil
            if imageArr != nil
            {
                if imageArr!.count > 0
                {
                    imageLabel.image = imageArr![0]
                }
            }
        }
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var imageLabel: UIImageView!
    @IBOutlet weak var profileImgLabel: UIImageView!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        profileImgLabel.layer.cornerRadius = CGFloat(4.0)
        profileImgLabel.clipsToBounds = true
        imageLabel.layer.cornerRadius = CGFloat(8.0)
        imageLabel.clipsToBounds = true
    }
}
