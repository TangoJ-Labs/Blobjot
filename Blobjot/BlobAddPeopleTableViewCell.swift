//
//  BlobAddPeopleTableViewCell.swift
//  Blobjot
//
//  Created by Sean Hart on 8/1/16.
//  Copyright © 2016 tangojlabs. All rights reserved.
//

import UIKit


class BlobAddPeopleTableViewCell: UITableViewCell {
    
    // Declare the view components
    var cellContainer: UIView!
    var cellUserImage: UIImageView!
    var cellUserImageActivityIndicator: UIActivityIndicatorView!
    var cellUserName: UILabel!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: Constants.Dim.blobAddPeopleTableViewCellHeight))
        cellContainer.backgroundColor = Constants.Colors.standardBackground
        self.addSubview(cellContainer)
        
        print("CELL CONTAINER FRAME: \(cellContainer.frame)")
        
        let imageSize = cellContainer.frame.height - 10
        cellUserImage = UIImageView(frame: CGRect(x: cellContainer.frame.width - 10 - imageSize, y: 5, width: imageSize, height: imageSize))
        cellUserImage.layer.cornerRadius = imageSize / 2
        cellUserImage.contentMode = UIViewContentMode.ScaleAspectFill
        cellUserImage.clipsToBounds = true
        cellContainer.addSubview(cellUserImage)
        
        // Add a loading indicator while the Image is downloaded / searched for
        // Give it the same size and location as the Image View
        cellUserImageActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: cellContainer.frame.width - 10 - imageSize, y: 5, width: imageSize, height: imageSize))
        cellUserImageActivityIndicator.color = UIColor.blackColor()
        cellContainer.addSubview(cellUserImageActivityIndicator)
        
        cellUserName = UILabel(frame: CGRect(x: 15, y: 15, width: cellContainer.frame.width - 30 - cellUserImage.frame.width, height: 30))
        cellUserName.font = UIFont(name: Constants.Strings.fontRegular, size: 24)
        cellContainer.addSubview(cellUserName)
        
        let border1 = CALayer()
        border1.frame = CGRect(x: 10, y: cellContainer.frame.height - 1, width: cellContainer.frame.width - 20, height: 1)
        border1.backgroundColor = Constants.Colors.blobGray.CGColor
        cellContainer.layer.addSublayer(border1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
