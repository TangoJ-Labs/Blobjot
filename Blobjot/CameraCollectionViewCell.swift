//
//  CameraCollectionViewCell.swift
//  Blobjot
//
//  Created by Sean Hart on 2/21/17.
//  Copyright © 2017 blobjot. All rights reserved.
//

import UIKit

class CameraCollectionViewCell: UICollectionViewCell
{
    var imageContainer: UIView!
    var imageView: UIImageView!
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        imageContainer = UIView(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height))
        imageContainer.backgroundColor = UIColor.clear // Constants.Colors.colorCameraImageCellBackground
        contentView.addSubview(imageContainer)
        
        // The Preview Box User Image should fill the height of the Preview Box, be circular in shape, and on the left side of the Preview Box
        let cellImageGap = (Constants.Dim.cameraViewImageCellSize - Constants.Dim.cameraViewImageSize) / 2
        imageView = UIImageView(frame: CGRect(x: cellImageGap, y: cellImageGap, width: Constants.Dim.cameraViewImageSize, height: Constants.Dim.cameraViewImageSize))
        imageView.layer.cornerRadius = Constants.Dim.cameraViewImageSize / 2
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = false
        imageView.backgroundColor = UIColor.black
        imageContainer.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
