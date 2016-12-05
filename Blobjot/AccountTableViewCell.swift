//
//  AccountTableViewCell.swift
//  Blobjot
//
//  Created by Sean Hart on 7/28/16.
//  Copyright © 2016 tangojlabs. All rights reserved.
//

import UIKit

class AccountTableViewCell: UITableViewCell {
    
    var cellContainer: UIView!
    var cellBlobTypeIndicator: UIView!
    var cellDate: UILabel!
    var cellTime: UILabel!
    var cellText: UILabel!
    var cellSelectedActivityIndicator: UIActivityIndicatorView!
    var cellThumbnail: UIImageView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        cellBlobTypeIndicator = UIView(frame: CGRect(x: 2, y: 2, width: Constants.Dim.blobsActiveTableViewIndicatorSize, height: Constants.Dim.blobsActiveTableViewIndicatorSize))
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
        
        cellDate = UILabel(frame: CGRect(x: 5 + (Constants.Dim.blobsUserTableViewIndicatorSize / 2), y: 25, width: cellContainer.frame.width - 10 - Constants.Dim.blobsUserTableViewContentSize - (Constants.Dim.blobsUserTableViewIndicatorSize / 2), height: 30))
        cellDate.font = UIFont(name: Constants.Strings.fontRegular, size: 18)
//        cellDate.textColor = Constants.Colors.colorTextStandard
        cellContainer.addSubview(cellDate)
        
        cellTime = UILabel(frame: CGRect(x: 5 + (Constants.Dim.blobsUserTableViewIndicatorSize / 2), y: 45, width: cellContainer.frame.width - 10 - Constants.Dim.blobsUserTableViewContentSize - (Constants.Dim.blobsUserTableViewIndicatorSize / 2), height: 30))
        cellTime.font = UIFont(name: Constants.Strings.fontRegular, size: 10)
//        cellTime.textColor = Constants.Colors.colorTextStandard
        cellContainer.addSubview(cellTime)
        
        cellText = UILabel(frame: CGRect(x: cellContainer.frame.width - cellContainer.frame.height, y: 0, width: cellContainer.frame.height, height: cellContainer.frame.height))
        cellText.font = UIFont(name: Constants.Strings.fontRegular, size: 10)
        cellText.textAlignment = .center
        cellText.numberOfLines = 4
        cellText.lineBreakMode = NSLineBreakMode.byWordWrapping
        cellContainer.addSubview(cellText)
        
        // Add a loading indicator to display when the user has selected the row
        cellSelectedActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: cellContainer.frame.width - 5 - (Constants.Dim.blobsUserTableViewContentSize * 2), y: 0, width: Constants.Dim.blobsUserTableViewContentSize, height: Constants.Dim.blobsUserTableViewContentSize))
        cellSelectedActivityIndicator.color = UIColor.black
        cellContainer.addSubview(cellSelectedActivityIndicator)
        
//        cellBlobTypeIndicator = UIView(frame: CGRect(x: cellContainer.frame.width - 5 - Constants.Dim.blobsUserTableViewContentSize - (Constants.Dim.blobsUserTableViewIndicatorSize / 2), y: 10, width: Constants.Dim.blobsUserTableViewIndicatorSize, height: Constants.Dim.blobsUserTableViewIndicatorSize))
//        cellBlobTypeIndicator.layer.cornerRadius = Constants.Dim.blobsUserTableViewIndicatorSize / 2
//        cellBlobTypeIndicator.layer.shadowOffset = CGSizeMake(0, 0.2)
//        cellBlobTypeIndicator.layer.shadowOpacity = 0.2
//        cellBlobTypeIndicator.layer.shadowRadius = 1.0
//        cellContainer.addSubview(cellBlobTypeIndicator)
        
        cellThumbnail = UIImageView(frame: CGRect(x: cellContainer.frame.width - cellContainer.frame.height, y: 0, width: cellContainer.frame.height, height: cellContainer.frame.height))
        cellThumbnail.contentMode = UIViewContentMode.scaleAspectFill
        cellThumbnail.clipsToBounds = true
        cellContainer.addSubview(cellThumbnail)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
//        print("SET SELECTED ACCOUNT VIEW CELL")
    }
    
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        print("USER CELL - SET SELECTED")
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
//        print("USER CELL - SET HIGHLIGHTED")
//        let color = cellBlobTypeIndicator.backgroundColor
//        super.setHighlighted(highlighted, animated: animated)
//        
//        if(highlighted) {
//            cellBlobTypeIndicator.backgroundColor = color
//        }
//    }
    
}
