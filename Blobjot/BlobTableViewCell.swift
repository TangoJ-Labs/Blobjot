//
//  BlobViewTableViewCell.swift
//  Blobjot
//
//  Created by Sean Hart on 10/23/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import GoogleMaps
import UIKit

class BlobTableViewCell: UITableViewCell
{
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = Constants.Colors.standardBackground
        
        let clearView = UIView()
        clearView.backgroundColor = UIColor.clear
        self.selectedBackgroundView = clearView
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
//        print("SELECTED BLOB CELL")
    }
    
}
