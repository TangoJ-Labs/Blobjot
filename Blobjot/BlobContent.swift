//
//  BlobComment.swift
//  Blobjot
//
//  Created by Sean Hart on 10/22/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import UIKit

class BlobContent {
    
    var blobContentID: String!
    var blobID: String!
    var userID: String!
    var contentDatetime: Date!
    var contentType: Int!
    var contentText: String?
    var contentThumbnailID: String?
    var contentMediaID: String?
    var contentThumbnail: UIImage?
    var contentImage: UIImage?
    
    // A local variable to use when constructing the content view
    var contentHeight: CGFloat?
    
    convenience init(blobContentID: String!, blobID: String!, userID: String!, contentDatetime: Date!, contentType: Int!, contentText: String?, contentMediaID: String?, contentThumbnailID: String?) {
        self.init()
        
        self.blobContentID      = blobContentID
        self.blobID             = blobID
        self.userID             = userID
        self.contentDatetime    = contentDatetime
        self.contentType        = contentType
        self.contentText        = contentText
        self.contentMediaID     = contentMediaID
        self.contentThumbnailID = contentThumbnailID

    }
    
}
