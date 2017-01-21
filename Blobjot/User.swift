//
//  User.swift
//  Blobjot
//
//  Created by Sean Hart on 8/2/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import UIKit

class User {
    
    var facebookID: String!
    var userID: String?
    var userName: String?
    var userImage: UIImage?
    var userStatus: Constants.UserStatusType = Constants.UserStatusType.standard
    
    convenience init(facebookID: String, userID: String?, userName: String?, userImage: UIImage?)
    {
        self.init()
        
        self.userID = userID
        self.facebookID = facebookID
        self.userName = userName
        self.userImage = userImage
    }
}
