//
//  ListTableViewCell.swift
//  Blobjot
//
//  Created by Sean Hart on 7/26/16.
//  Copyright © 2016 tangojlabs. All rights reserved.
//

import UIKit

class BlobsActiveTableViewCell: UITableViewCell {
    
    var cellContainer: UIView!
    var cellBlobTypeIndicator: UIView!
    var cellUserImageContainer: UIView!
    var cellUserImage: UIImageView!
    var userImageActivityIndicator: UIActivityIndicatorView!
    var cellUserName: UILabel!
    var cellDatetime: UILabel!
    var cellText: UILabel!
    var cellSelectedActivityIndicator: UIActivityIndicatorView!
    var cellThumbnail: UIImageView!
    var thumbnailActivityIndicator: UIActivityIndicatorView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        cellBlobTypeIndicator = UIView(frame: CGRect(x: 0 - 5, y: 2, width: Constants.Dim.blobsActiveTableViewIndicatorSize, height: Constants.Dim.blobsActiveTableViewIndicatorSize))
        cellBlobTypeIndicator.layer.cornerRadius = Constants.Dim.blobsActiveTableViewIndicatorSize / 2
        cellBlobTypeIndicator.layer.shadowOffset = CGSize(width: 0, height: 0.2)
        cellBlobTypeIndicator.layer.shadowOpacity = 0.2
        cellBlobTypeIndicator.layer.shadowRadius = 1.0
        self.addSubview(cellBlobTypeIndicator)
        
        cellContainer = UIView(frame: CGRect(x: 15, y: 5, width: self.frame.width - 25, height: Constants.Dim.blobsActiveTableViewCellHeight - 10))
        cellContainer.layer.shadowOffset = Constants.Dim.cardShadowOffset
        cellContainer.layer.shadowOpacity = Constants.Dim.cardShadowOpacity
        cellContainer.layer.shadowRadius = Constants.Dim.cardShadowRadius
        cellContainer.backgroundColor = Constants.Colors.standardBackground
        self.addSubview(cellContainer)
        
        cellUserImageContainer = UIView(frame: CGRect(x: 5, y: (cellContainer.frame.height / 2) - (Constants.Dim.blobsActiveTableViewUserImageSize / 2), width: Constants.Dim.blobsActiveTableViewUserImageSize, height: Constants.Dim.blobsActiveTableViewUserImageSize))
        cellUserImageContainer.backgroundColor = Constants.Colors.standardBackground
        cellUserImageContainer.layer.cornerRadius = Constants.Dim.blobsActiveTableViewUserImageSize / 2
        cellContainer.addSubview(cellUserImageContainer)
        
        cellUserImage = UIImageView(frame: CGRect(x: 0, y: 0, width: Constants.Dim.blobsActiveTableViewUserImageSize, height: Constants.Dim.blobsActiveTableViewUserImageSize))
        cellUserImage.layer.cornerRadius = Constants.Dim.blobsActiveTableViewUserImageSize / 2
        cellUserImage.contentMode = UIViewContentMode.scaleAspectFill
        cellUserImage.clipsToBounds = true
        cellUserImageContainer.addSubview(cellUserImage)
        
        // Add a loading indicator while the User Image is searched for
        // Give it the same size and location as the User Image View
        userImageActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 5, y: 20, width: Constants.Dim.blobsActiveTableViewUserImageSize, height: Constants.Dim.blobsActiveTableViewUserImageSize))
        userImageActivityIndicator.color = UIColor.black
        cellContainer.addSubview(userImageActivityIndicator)
        
        cellUserName = UILabel(frame: CGRect(x: 10 + Constants.Dim.blobsActiveTableViewUserImageSize, y: 25, width: cellContainer.frame.width - 20 - Constants.Dim.blobsActiveTableViewUserImageSize - Constants.Dim.blobsActiveTableViewContentSize, height: 30))
        cellUserName.font = UIFont(name: Constants.Strings.fontRegular, size: 18)
        cellContainer.addSubview(cellUserName)
        
        cellDatetime = UILabel(frame: CGRect(x: 10 + Constants.Dim.blobsActiveTableViewUserImageSize, y: 20 + cellUserName.frame.height, width: cellContainer.frame.width - 20 - Constants.Dim.blobsActiveTableViewUserImageSize - Constants.Dim.blobsActiveTableViewContentSize, height: 15))
        cellDatetime.font = UIFont(name: Constants.Strings.fontRegular, size: 10)
        cellContainer.addSubview(cellDatetime)
        
        cellText = UILabel(frame: CGRect(x: cellContainer.frame.width - 5 - Constants.Dim.blobsActiveTableViewContentSize, y: 5, width: Constants.Dim.blobsActiveTableViewContentSize, height: Constants.Dim.blobsActiveTableViewContentSize))
        cellText.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        cellText.numberOfLines = 4
        cellText.lineBreakMode = NSLineBreakMode.byWordWrapping
        cellContainer.addSubview(cellText)
        
        // Add a loading indicator to display when the user has selected the row
        cellSelectedActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: cellContainer.frame.width - 5 - (Constants.Dim.blobsActiveTableViewContentSize * 2), y: 0, width: Constants.Dim.blobsActiveTableViewContentSize, height: Constants.Dim.blobsActiveTableViewContentSize))
        cellSelectedActivityIndicator.color = UIColor.black
        cellContainer.addSubview(cellSelectedActivityIndicator)
        
        cellThumbnail = UIImageView(frame: CGRect(x: cellContainer.frame.width - cellContainer.frame.height, y: 0, width: cellContainer.frame.height, height: cellContainer.frame.height))
        cellThumbnail.contentMode = UIViewContentMode.scaleAspectFill
        cellThumbnail.clipsToBounds = true
        cellContainer.addSubview(cellThumbnail)
        
        // Add a loading indicator while the Thumbnail is searched for
        // Give it the same size and location as the Thumbnail Image View
        thumbnailActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: cellContainer.frame.width - 5 - Constants.Dim.blobsActiveTableViewContentSize, y: 5, width: cellThumbnail.frame.width, height: cellThumbnail.frame.height))
        thumbnailActivityIndicator.color = UIColor.black
        cellContainer.addSubview(thumbnailActivityIndicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        print("SELECTED ACTIVE BLOB VIEW CELL")
    }

//    override func setSelected(_ selected: Bool, animated: Bool) {
//        print("ACTIVE CELL - SET SELECTED")
//        // Configure the view for the selected state
//        let color = cellBlobTypeIndicator.backgroundColor
//        super.setSelected(selected, animated: animated)
//        
//        if(selected) {
//            cellBlobTypeIndicator.backgroundColor = color
//        }
//    }
//    
//    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
//        print("ACTIVE CELL - SET HIGHLIGHTED")
//        let color = cellBlobTypeIndicator.backgroundColor
//        super.setHighlighted(highlighted, animated: animated)
//        
//        if(highlighted) {
//            cellBlobTypeIndicator.backgroundColor = color
//        }
//    }

}
