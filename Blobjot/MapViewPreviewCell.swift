//
//  MapViewBlobPreviewTableViewCell.swift
//  Blobjot
//
//  Created by Sean Hart on 12/31/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import UIKit

class MapViewPreviewCell: UICollectionViewCell
{
    var previewContainer: UIView!
    var previewTimeLabel: UILabel!
    var previewUserNameLabel: UILabel!
    var previewUserNameActivityIndicator: UIActivityIndicatorView!
    var previewUserImageView: UIImageView!
    var previewUserImageActivityIndicator: UIActivityIndicatorView!
    var previewBlobTypeIndicator: UIView!
    var previewTextBox: UILabel!
    var previewThumbnailView: UIImageView!
    var previewThumbnailActivityIndicator: UIActivityIndicatorView!
    
    // Use the same size as the collection view items for the Preview User Image
    let previewUserImageSize = Constants.Dim.mapViewLocationBlobsCVItemSize
    
    // Set the Preview Time Label Width for use with multiple views
    let previewTimeLabelWidth: CGFloat = 100
    
    var postUserImageOffset: CGFloat = 0
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
//        // Add the Preview Box to be the same size as the Search Box
//        // Initialize with the Y location as negative (hide the box) just like the Search Box
//        previewContainer = UIView(frame: CGRect(x: 0, y: 0 - Constants.Dim.mapViewPreviewContainerHeight, width: self.frame.width, height: Constants.Dim.mapViewPreviewContainerHeight))
//        previewContainer.backgroundColor = Constants.Colors.standardBackground
//        previewContainer.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
//        previewContainer.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
//        previewContainer.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
//        previewContainer.isUserInteractionEnabled = true
//        self.addSubview(previewContainer)
        
        previewContainer = UIView(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height))
        previewContainer.backgroundColor = Constants.Colors.standardBackground
        contentView.addSubview(previewContainer)
        
        // The Preview Box User Image should fill the height of the Preview Box, be circular in shape, and on the left side of the Preview Box
        previewUserImageView = UIImageView(frame: CGRect(x: previewContainer.frame.height / 2 + 5, y: 3, width: previewUserImageSize, height: previewUserImageSize))
        previewUserImageView.layer.cornerRadius = Constants.Dim.mapViewLocationBlobsCVItemSize / 2
        previewUserImageView.contentMode = UIViewContentMode.scaleAspectFill
        previewUserImageView.clipsToBounds = true
        previewUserImageView.isUserInteractionEnabled = true
        previewContainer.addSubview(previewUserImageView)
        
        // Add a loading indicator in case the User Image is still downloading when the Preview Box is shown
        // Give it the same size and location as the previewUserImageView
        previewUserImageActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: previewContainer.frame.height / 2 + 5, y: 5, width: previewUserImageSize, height: previewUserImageSize))
        previewUserImageActivityIndicator.color = UIColor.black
        previewContainer.addSubview(previewUserImageActivityIndicator)
        
        postUserImageOffset = previewContainer.frame.height / 2 + 10 + previewUserImageSize
        // The Preview Box User Name Label should start just to the right (5dp margin) of the Preview Box User Image and extend to the Time Label
        previewUserNameLabel = UILabel(frame: CGRect(x: postUserImageOffset, y: 5, width: previewContainer.frame.width - 10 - postUserImageOffset - previewTimeLabelWidth, height: 15))
        previewUserNameLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        previewUserNameLabel.textColor = Constants.Colors.colorTextGrayLight
        previewUserNameLabel.textAlignment = .left
        previewUserNameLabel.isUserInteractionEnabled = false
        previewContainer.addSubview(previewUserNameLabel)
        
        // Add a loading indicator in case the User Name is still downloading when the Preview Box is shown
        // Give it the same size and location as the previewUserNameLabel
        previewUserNameActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: postUserImageOffset, y: 5, width: 25, height: 15))
        previewUserNameActivityIndicator.color = UIColor.black
        previewContainer.addSubview(previewUserNameActivityIndicator)
        
        // The Preview Box Time Label should start just to the right of the Preview Box User Name and extend to the Thumbnail Image
        // Because the Thumbnail Image is square, you can use the Preview Container Height as a substitute for calculating the Thumbnail Image width
        previewTimeLabel = UILabel(frame: CGRect(x: previewContainer.frame.width - 5 - previewContainer.frame.height / 2 - previewTimeLabelWidth, y: 5, width: previewTimeLabelWidth, height: 15))
        previewTimeLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        previewTimeLabel.textColor = Constants.Colors.colorTextGrayLight
        previewTimeLabel.textAlignment = .right
        previewTimeLabel.isUserInteractionEnabled = false
        previewContainer.addSubview(previewTimeLabel)
        
        // The Preview Box Text Box should be a single line of text (UILabel is sufficient), have the same X location and width as the
        // Preview Box User Name Label, and be placed just below the User Name Label
        previewTextBox = UILabel(frame: CGRect(x: postUserImageOffset, y: 10 + previewUserNameLabel.frame.height, width: previewContainer.frame.width - 10 - postUserImageOffset - previewTimeLabelWidth, height: 15))
        previewTextBox.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        previewTextBox.isUserInteractionEnabled = false
        previewContainer.addSubview(previewTextBox)
        
        // The Preview Box Thumbnail View should be square and on the right side of the Preview Box
        previewThumbnailView = UIImageView(frame: CGRect(x: previewContainer.frame.width - 5 - previewContainer.frame.height / 2 - Constants.Dim.mapViewPreviewContainerHeight, y: 0, width: Constants.Dim.mapViewPreviewContainerHeight, height: Constants.Dim.mapViewPreviewContainerHeight))
        previewThumbnailView.contentMode = UIViewContentMode.scaleAspectFill
        previewThumbnailView.clipsToBounds = true
        previewThumbnailView.isUserInteractionEnabled = false
        
        // Add a loading indicator in case the Thumbnail is still loading when the Preview Box is shown
        // Give it the same size and location as the previewThumbnailView
        previewThumbnailActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: previewContainer.frame.width - 5 - previewContainer.frame.height / 2 - Constants.Dim.mapViewPreviewContainerHeight, y: 0, width: Constants.Dim.mapViewPreviewContainerHeight, height: Constants.Dim.mapViewPreviewContainerHeight))
        previewThumbnailActivityIndicator.color = UIColor.black
        previewContainer.addSubview(previewThumbnailActivityIndicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
