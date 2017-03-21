//
//  MapViewPreviewSubCell.swift
//  Blobjot
//
//  Created by Sean Hart on 3/13/17.
//  Copyright © 2017 blobjot. All rights reserved.
//

import UIKit

class MapViewPreviewSubCell: UICollectionViewCell
{
    var previewSubCellContainer: UIView!
    var blobImageView: UIImageView!
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        previewSubCellContainer = UIView(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height))
        previewSubCellContainer.backgroundColor = UIColor.brown //Constants.Colors.standardBackground
        contentView.addSubview(previewSubCellContainer)
        
        blobImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: previewSubCellContainer.frame.width, height: previewSubCellContainer.frame.height))
        previewSubCellContainer.addSubview(blobImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
