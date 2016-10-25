//
//  BlobViewTableViewCell.swift
//  Blobjot
//
//  Created by Sean Hart on 10/23/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import UIKit

class BlobTableViewCell: UITableViewCell
{
    var cellContainer: UIView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        print("BTVC - CELL HEIGHT: \(self.frame.height)")
        self.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight
        
        cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        cellContainer.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight
        self.addSubview(cellContainer)
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
