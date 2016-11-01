//
//  PeopleTableViewCell.swift
//  Blobjot
//
//  Created by Sean Hart on 8/1/16.
//  Copyright © 2016 tangojlabs. All rights reserved.
//

import UIKit

class PeopleTableViewCell: UITableViewCell {

    var cellContainer: UIView!
    var cellConnectIndicator: UIImageView!
    var cellUserImage: UIImageView!
    var cellUserImageActivityIndicator: UIActivityIndicatorView!
    var cellActionMessage: UILabel!
    var cellUserName: UILabel!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        cellContainer = UIView(frame: CGRect(x: 10, y: 5, width: self.frame.width - 20, height: Constants.Dim.peopleTableViewCellHeight - 10))
        cellContainer.backgroundColor = Constants.Colors.standardBackground
        cellContainer.layer.shadowOffset = Constants.Dim.cardShadowOffset
        cellContainer.layer.shadowOpacity = Constants.Dim.cardShadowOpacity
        cellContainer.layer.shadowRadius = Constants.Dim.cardShadowRadius
        self.addSubview(cellContainer)
        
        print("CELL CONTAINER FRAME: \(cellContainer.frame)")
        
        cellConnectIndicator = UIImageView(frame: CGRect(x: 10, y: (cellContainer.frame.height / 2) - (Constants.Dim.peopleConnectIndicatorSize / 2), width: Constants.Dim.peopleConnectIndicatorSize, height: Constants.Dim.peopleConnectIndicatorSize))
        cellConnectIndicator.image = UIImage(named: Constants.Strings.iconStringConnectionViewAddConnection)
        cellConnectIndicator.contentMode = UIViewContentMode.scaleAspectFit
        cellConnectIndicator.clipsToBounds = true
        cellContainer.addSubview(cellConnectIndicator)
        
        let imageSize = Constants.Dim.peopleTableViewUserImageSize
        cellUserImage = UIImageView(frame: CGRect(x: cellContainer.frame.width - 10 - imageSize, y: (cellContainer.frame.height / 2) - (imageSize / 2), width: imageSize, height: imageSize))
        cellUserImage.layer.cornerRadius = imageSize / 2
        cellUserImage.contentMode = UIViewContentMode.scaleAspectFill
        cellUserImage.clipsToBounds = true
        cellContainer.addSubview(cellUserImage)
        
        // Add a loading indicator while the Image is downloaded / searched for
        // Give it the same size and location as the Image View
        cellUserImageActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: cellContainer.frame.width - 10 - imageSize, y: (cellContainer.frame.height / 2) - (imageSize / 2), width: imageSize, height: imageSize))
        cellUserImageActivityIndicator.color = UIColor.black
        cellContainer.addSubview(cellUserImageActivityIndicator)
        
        cellUserName = UILabel(frame: CGRect(x: 15 + cellConnectIndicator.frame.width, y: (cellContainer.frame.height / 2) - 15, width: cellContainer.frame.width - 30 - cellConnectIndicator.frame.width - cellUserImage.frame.width, height: 30))
        cellUserName.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        cellContainer.addSubview(cellUserName)
        
        cellActionMessage = UILabel(frame: CGRect(x: 15 + cellConnectIndicator.frame.width, y: 5, width: cellContainer.frame.width - 30 - cellConnectIndicator.frame.width - cellUserImage.frame.width, height: 30))
        cellActionMessage.font = UIFont(name: Constants.Strings.fontRegular, size: 8)
        cellActionMessage.textAlignment = NSTextAlignment.left
        cellContainer.addSubview(cellActionMessage)
        
//        let border1 = CALayer()
//        border1.frame = CGRect(x: 10, y: cellContainer.frame.height - 1, width: cellContainer.frame.width - 20, height: 1)
//        border1.backgroundColor = Constants.Colors.blobGray.cgColor
//        cellContainer.layer.addSublayer(border1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        print("SELECTED ACCOUNT VIEW CELL")
    }
    
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//        // Configure the view for the selected state
//    }

}
