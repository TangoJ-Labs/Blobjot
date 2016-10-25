//
//  BlobComment.swift
//  Blobjot
//
//  Created by Sean Hart on 10/22/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import UIKit

class BlobComment {
    
    var commentID: String!
    var blobID: String!
    var userID: String!
    var commentDatetime: Date!
    var comment: String!
    
    convenience init(commentID: String!, blobID: String!, userID: String!, commentDatetime: Date!, comment: String!) {
        self.init()
        
        self.commentID       = commentID
        self.blobID          = blobID
        self.userID          = userID
        self.commentDatetime = commentDatetime
        self.comment         = comment

    }
    
}
