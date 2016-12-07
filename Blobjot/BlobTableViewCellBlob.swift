//
//  BlobViewTableViewCell.swift
//  Blobjot
//
//  Created by Sean Hart on 10/23/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import GoogleMaps
import UIKit

class BlobTableViewCellBlob: UITableViewCell
{
//    var cellContainer: UIView!
//    
//    var userImageContainer: UIView!
//    var userImageView: UIImageView!
//    var blobTypeIndicatorView: UIView!
//    var blobDatetimeLabel: UILabel!
//    var blobDateAgeLabel: UILabel!
//    var blobTextViewContainer: UIView!
//    var blobTextView: UITextView!
//    var blobImageView: UIImageView!
//    var mapView: GMSMapView!
//    var blobMediaActivityIndicator: UIActivityIndicatorView!
//    var commentLabel: UILabel!
//    
//    var blobCircle: GMSCircle!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight
        
        let clearView = UIView()
        clearView.backgroundColor = UIColor.clear
        self.selectedBackgroundView = clearView
//        self.selectionStyle = UITableViewCellSelectionStyle.none
        
//        self.backgroundColor = UIColor.blue
        
//        cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
//        cellContainer.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight
//        self.addSubview(cellContainer)
        
//        // The User Image should be in the upper right quadrant
//        userImageContainer = UIImageView(frame: CGRect(x: 5, y: cellContainer.frame.height - 10 - Constants.Dim.blobViewUserImageSize - cellContainer.frame.width, width: Constants.Dim.blobViewUserImageSize, height: Constants.Dim.blobViewUserImageSize))
//        userImageContainer.layer.cornerRadius = Constants.Dim.blobViewUserImageSize / 2
//        cellContainer.addSubview(userImageContainer)
//        
//        userImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: userImageContainer.frame.width, height: userImageContainer.frame.height))
//        userImageView.layer.cornerRadius = Constants.Dim.blobViewUserImageSize / 2
//        userImageView.contentMode = UIViewContentMode.scaleAspectFill
//        userImageView.clipsToBounds = true
//        userImageContainer.addSubview(userImageView)
//        
//        
//        // The Blob Type Indicator should be to the top right of the the User Image
//        blobTypeIndicatorView = UIView(frame: CGRect(x: 5, y: 5, width: Constants.Dim.blobViewIndicatorSize, height: Constants.Dim.blobViewIndicatorSize))
//        blobTypeIndicatorView.layer.cornerRadius = Constants.Dim.blobViewIndicatorSize / 2
//        blobTypeIndicatorView.layer.shadowOffset = CGSize(width: 0, height: 0.2)
//        blobTypeIndicatorView.layer.shadowOpacity = 0.2
//        blobTypeIndicatorView.layer.shadowRadius = 1.0
//        blobTypeIndicatorView.isUserInteractionEnabled = true
//        self.addSubview(blobTypeIndicatorView)
//
//        // The Date Age Label should be in small font just below the Navigation Bar at the right of the screen (right aligned text)
//        blobDateAgeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: blobTypeIndicatorView.frame.width, height: blobTypeIndicatorView.frame.height))
//        blobDateAgeLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 10)
//        blobDateAgeLabel.textColor = Constants.Colors.colorTextGray
//        blobDateAgeLabel.textAlignment = .center
//        blobTypeIndicatorView.addSubview(blobDateAgeLabel)
//        
//        // The Datetime Label should be in small font just below the Navigation Bar starting at the left of the screen (left aligned text)
//        blobDatetimeLabel = UILabel(frame: CGRect(x: cellContainer.frame.width / 2 - 2, y: 2, width: cellContainer.frame.width / 2 - 2, height: 15))
//        blobDatetimeLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 10)
//        blobDatetimeLabel.textColor = Constants.Colors.colorTextGray
//        blobDatetimeLabel.textAlignment = .right
//        cellContainer.addSubview(blobDatetimeLabel)
//        
//        // The Text View should be in the upper left quadrant of the screen (to the left of the User Image), and should extend into the upper right quadrant nearing the User Image
//        blobTextViewContainer = UIView(frame: CGRect(x: 10 + Constants.Dim.blobViewUserImageSize, y: 50, width: cellContainer.frame.width - 15 - Constants.Dim.blobViewUserImageSize, height: cellContainer.frame.height - 60 - cellContainer.frame.width))
//        blobTextViewContainer.backgroundColor = UIColor.green
//        blobTextViewContainer.layer.cornerRadius = 10
//        blobTextViewContainer.layer.shadowOffset = CGSize(width: 0, height: 0.2)
//        blobTextViewContainer.layer.shadowOpacity = 0.5
//        blobTextViewContainer.layer.shadowRadius = 2.0
//        cellContainer.addSubview(blobTextViewContainer)
//        
//        print("BTVC-B - CELL HEIGHT: \(cellContainer.frame.height)")
//        print("BTVC-B - TEXT VIEW HEIGHT: \(blobTextViewContainer.frame.height)")
//        
//        blobTextView = UITextView(frame: CGRect(x: 0, y: 0, width: blobTextViewContainer.frame.width, height: blobTextViewContainer.frame.height))
//        blobTextView.backgroundColor = UIColor.blue
//        blobTextView.layer.cornerRadius = 10
//        blobTextView.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
//        blobTextView.isScrollEnabled = true
//        blobTextView.isEditable = false
//        blobTextView.isSelectable = false
//        blobTextViewContainer.addSubview(blobTextView)
//        
//        // The Media Content View should be in the lower half of the screen (partially extending into the upper half)
//        // It should span the width of the screen
//        // The Image View or the Video Player will be used based on the content (both are the same size, in the same position)
//        let blobImageSize = cellContainer.frame.width
//        
//        blobImageView = UIImageView(frame: CGRect(x: 0, y: cellContainer.frame.height - blobImageSize, width: blobImageSize, height: blobImageSize))
//        blobImageView.contentMode = UIViewContentMode.scaleAspectFill
//        blobImageView.clipsToBounds = true
//        cellContainer.addSubview(blobImageView)
//        
//        // Add a loading indicator until the Media has downloaded
//        // Give it the same size and location as the blobImageView
//        blobMediaActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: cellContainer.frame.height - cellContainer.frame.width, width: cellContainer.frame.width, height: cellContainer.frame.width))
//        blobMediaActivityIndicator.color = UIColor.black
//        cellContainer.addSubview(blobMediaActivityIndicator)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse()
    {
//        cellContainer = UIView()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        print("SELECTED BLOB CELL")
    }
    
}
