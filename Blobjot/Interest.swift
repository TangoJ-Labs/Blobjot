//
//  Interest.swift
//  Blobjot
//
//  Created by Sean Hart on 1/28/17.
//  Copyright © 2017 blobjot. All rights reserved.
//

import UIKit

class Interest
{
    var interest: String!
    
    var use: Bool = true
    var delete: Bool = true
    
    convenience init(interest: String)
    {
        self.init()
        
        self.interest = interest
    }
    
}
