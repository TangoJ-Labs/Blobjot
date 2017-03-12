//
//  User.swift
//  Blobjot
//
//  Created by Sean Hart on 8/2/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import UIKit

class User {
    
    var digitsID: String!
    var userID: String!
    var userName: String?
    var userImageID: String?
    var userImage: UIImage?
    
    convenience init(digitsID: String!, userID: String!, userName: String?, userImageID: String?, userImage: UIImage?)
    {
        self.init()
        
        self.digitsID = digitsID
        self.userID = userID
        self.userName = userName
        self.userImageID = userImageID
        self.userImage = userImage
    }
}
