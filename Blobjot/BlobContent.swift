//
//  BlobComment.swift
//  Blobjot
//
//  Created by Sean Hart on 10/22/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import UIKit

class BlobContent
{
    var blobContentID: String!
    var blobID: String!
    var userID: String!
    var contentDatetime: Date!
    var contentType: Constants.ContentType!
    var contentText: String?
    var contentThumbnailID: String?
    var contentMediaID: String?
    var response: Bool = false
    var respondingToContentID: String!
    
    var contentThumbnail: UIImage?
    var contentImage: UIImage?
    
    var contentExtraRequested = false
    var contentViewed = false
    var blobSelected = false
    
    // Properties of the associated Blob
    var blobType: Constants.BlobType?
    var blobAccount = Constants.BlobAccount.standard
    var blobFeature = Constants.BlobFeature.standard
    var blobAccess = Constants.BlobAccess.followers
    
    // A local variable to use when constructing the content view
    var contentHeight: CGFloat?
    
    convenience init(blobContentID: String!, blobID: String!, userID: String!, contentDatetime: Date!, contentType: Constants.ContentType!, response: Bool!, contentText: String?, contentMediaID: String?, contentThumbnailID: String?, respondingToContentID: String?)
    {
        self.init()
        
        self.blobContentID      = blobContentID
        self.blobID             = blobID
        self.userID             = userID
        self.contentDatetime    = contentDatetime
        self.contentType        = contentType
        self.contentText        = contentText
        self.contentMediaID     = contentMediaID
        self.contentThumbnailID = contentThumbnailID
        
        self.response               = response
        self.respondingToContentID  = respondingToContentID
    }
    
}
