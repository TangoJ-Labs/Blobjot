//
//  CustomIdentityProvider.swift
//  Blobjot
//
//  Created by Sean Hart on 9/5/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import AWSCognito
import Foundation


class CustomIdentityProvider: NSObject, AWSIdentityProviderManager {
    var tokens : [NSString : NSString]?
    init(tokens: [NSString : NSString]) {
        self.tokens = tokens
    }
    @objc func logins() -> AWSTask {
        return AWSTask(result: tokens)
    }
}
