//
//  BlobTableViewCellComment.swift
//  Blobjot
//
//  Created by Sean Hart on 10/25/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import UIKit

class BlobTableViewCellComment: UITableViewCell
{
//    var cellContainer: UIView!
    
//    var addCommentView: UITextView!
//    var userImageView: UIImageView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        print("BTVC - CELL HEIGHT: \(self.frame.height)")
        self.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight
        
        let clearView = UIView()
        clearView.backgroundColor = UIColor.clear
        self.selectedBackgroundView = clearView
//        self.selectionStyle = UITableViewCellSelectionStyle.none
        
//        cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
//        cellContainer.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight
//        self.addSubview(cellContainer)
        
//        let commentBoxWidth = cellContainer.frame.width - 30 - Constants.Dim.blobViewCommentUserImageSize
        
//        let addCommentViewOffsetX = 10 + Constants.Dim.blobViewCommentUserImageSize
//        addCommentView = UITextView(frame: CGRect(x: addCommentViewOffsetX, y: 2, width: self.frame.width - 5 - addCommentViewOffsetX, height: self.frame.height - 4))
//        addCommentView.backgroundColor = Constants.Colors.colorPurpleLight
//        addCommentView.layer.cornerRadius = 5
//        addCommentView.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
//        addCommentView.text = "TEST"
//        addCommentView.isScrollEnabled = false
//        addCommentView.isEditable = false
//        addCommentView.isSelectable = false
//        cellContainer.addSubview(addCommentView)
//        
//        // Add an imageview for the user image for the comment (ONLY IF THE USER IS NOT THE CURRENT USER)
//        userImageView = UIImageView(frame: CGRect(x: 5, y: 5, width: Constants.Dim.blobViewCommentUserImageSize, height: Constants.Dim.blobViewCommentUserImageSize))
//        userImageView.layer.cornerRadius = Constants.Dim.blobViewCommentUserImageSize / 2
//        userImageView.contentMode = UIViewContentMode.scaleAspectFill
//        userImageView.clipsToBounds = true
//        cellContainer.addSubview(userImageView)
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
        print("SELECTED BLOB COMMENT CELL")
    }
    
}
