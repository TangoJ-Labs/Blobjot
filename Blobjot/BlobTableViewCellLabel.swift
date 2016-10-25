//
//  BlobTableViewCellLabel.swift
//  Blobjot
//
//  Created by Sean Hart on 10/25/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import UIKit

class BlobTableViewCellLabel: UITableViewCell
{
    var cellContainer: UIView!
    var commentLabel: UILabel!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        print("BTVC - CELL HEIGHT: \(self.frame.height)")
        self.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight
        
        cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        cellContainer.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight
        self.addSubview(cellContainer)
        
        commentLabel = UILabel(frame: CGRect(x: 0, y: 0, width: cellContainer.frame.width, height: cellContainer.frame.height))
        commentLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        commentLabel.textColor = Constants.Colors.colorTextGray
        commentLabel.text = ""
        commentLabel.textAlignment = .center
        cellContainer.addSubview(commentLabel)
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
        cellContainer = UIView()
    }
    
}
