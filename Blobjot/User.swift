//
//  User.swift
//  Blobjot
//
//  Created by Sean Hart on 8/2/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import UIKit

class User {
    
    var userID: String!
    var facebookID: String!
    var userName: String?
    var userImageUrl: String?
    var userImage: UIImage?
    var userStatus: Constants.UserStatusTypes = Constants.UserStatusTypes.notConnected
    
}
