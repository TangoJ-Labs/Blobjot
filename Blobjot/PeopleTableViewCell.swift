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
    var cellConnectStar: UIImageView!
    var cellUserImage: UIImageView!
    var cellUserImageActivityIndicator: UIActivityIndicatorView!
    var cellActionMessage: UILabel!
    var cellUserName: UILabel!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: Constants.Dim.peopleTableViewCellHeight))
        cellContainer.backgroundColor = Constants.Colors.standardBackground
        self.addSubview(cellContainer)
        
        print("CELL CONTAINER FRAME: \(cellContainer.frame)")
        
        cellConnectStar = UIImageView(frame: CGRect(x: 10, y: (cellContainer.frame.height - Constants.Dim.peopleConnectStarSize) / 2, width: Constants.Dim.peopleConnectStarSize, height: Constants.Dim.peopleConnectStarSize))
        cellConnectStar.contentMode = UIViewContentMode.scaleAspectFill
        cellConnectStar.clipsToBounds = true
        cellContainer.addSubview(cellConnectStar)
        
        let imageSize = cellContainer.frame.height - 10
        cellUserImage = UIImageView(frame: CGRect(x: cellContainer.frame.width - 10 - imageSize, y: 5, width: imageSize, height: imageSize))
        cellUserImage.layer.cornerRadius = imageSize / 2
        cellUserImage.contentMode = UIViewContentMode.scaleAspectFill
        cellUserImage.clipsToBounds = true
        cellContainer.addSubview(cellUserImage)
        
        // Add a loading indicator while the Image is downloaded / searched for
        // Give it the same size and location as the Image View
        cellUserImageActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: cellContainer.frame.width - 10 - imageSize, y: 5, width: imageSize, height: imageSize))
        cellUserImageActivityIndicator.color = UIColor.black
        cellContainer.addSubview(cellUserImageActivityIndicator)
        
        cellActionMessage = UILabel(frame: CGRect(x: 15 + cellConnectStar.frame.width, y: 5, width: cellContainer.frame.width - 30 - cellConnectStar.frame.width - cellUserImage.frame.width, height: 30))
        cellActionMessage.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        cellActionMessage.textAlignment = NSTextAlignment.left
        cellContainer.addSubview(cellActionMessage)
        
        cellUserName = UILabel(frame: CGRect(x: 15 + cellConnectStar.frame.width, y: 25, width: cellContainer.frame.width - 30 - cellConnectStar.frame.width - cellUserImage.frame.width, height: 30))
        cellUserName.font = UIFont(name: Constants.Strings.fontRegular, size: 24)
        cellContainer.addSubview(cellUserName)
        
        let border1 = CALayer()
        border1.frame = CGRect(x: 10, y: cellContainer.frame.height - 1, width: cellContainer.frame.width - 20, height: 1)
        border1.backgroundColor = Constants.Colors.blobGray.cgColor
        cellContainer.layer.addSublayer(border1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
