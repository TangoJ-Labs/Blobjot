//
//  LocationBlobsCollectionViewCell.swift
//  Blobjot
//
//  Created by Sean Hart on 7/24/16.
//  Copyright © 2016 tangojlabs. All rights reserved.
//

import UIKit

class MapViewLocationBlobsCell: UICollectionViewCell {
    
    var cellContainer: UIView!
    var userImageContainer: UIView!
    var userImage: UIImageView!
    var userImageActivityIndicator: UIActivityIndicatorView!
    var blobTypeIndicator: UIView!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height))
        cellContainer.backgroundColor = UIColor.clear
        contentView.addSubview(cellContainer)
        
        // Add a View Container for the User Image
        userImageContainer = UIView(frame: CGRect(x: 5, y: 5, width: Constants.Dim.mapViewLocationBlobsCVItemSize, height: Constants.Dim.mapViewLocationBlobsCVItemSize))
        userImageContainer.layer.cornerRadius = Constants.Dim.mapViewLocationBlobsCVItemSize / 2
        userImageContainer.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
        userImageContainer.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
        userImageContainer.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
        userImageContainer.backgroundColor = UIColor.white
        cellContainer.addSubview(userImageContainer)
        
        userImage = UIImageView(frame: CGRect(x: 0, y: 0, width: Constants.Dim.mapViewLocationBlobsCVItemSize, height: Constants.Dim.mapViewLocationBlobsCVItemSize))
        userImage.layer.cornerRadius = Constants.Dim.mapViewLocationBlobsCVItemSize / 2
        userImage.contentMode = UIViewContentMode.scaleAspectFill
        userImage.clipsToBounds = true
        userImageContainer.addSubview(userImage)
        
        // Add a loading indicator while the Image is downloaded / searched for
        // Give it the same size and location as the Image View
        userImageActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: Constants.Dim.mapViewLocationBlobsCVItemSize, height: Constants.Dim.mapViewLocationBlobsCVItemSize))
        userImageActivityIndicator.color = UIColor.black
        userImageContainer.addSubview(userImageActivityIndicator)
        
        blobTypeIndicator = UIView(frame: CGRect(x: 2, y: 2, width: Constants.Dim.mapViewLocationBlobsCVIndicatorSize, height: Constants.Dim.mapViewLocationBlobsCVIndicatorSize))
        blobTypeIndicator.layer.cornerRadius = Constants.Dim.mapViewLocationBlobsCVIndicatorSize / 2
        cellContainer.addSubview(blobTypeIndicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
