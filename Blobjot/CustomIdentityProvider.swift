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
    /**
     Each entry in logins represents a single login with an identity provider. The key is the domain of the login provider (e.g. 'graph.facebook.com') and the value is the OAuth/OpenId Connect token that results from an authentication with that login provider.
     */
    

    var tokens : [NSString : NSString]?
    init(tokens: [NSString : NSString]) {
        self.tokens = tokens
    }
//    @objc func logins() -> AWSTask<AnyObject> {
//        return AWSTask(result: tokens)
//    }
    
    public func logins() -> AWSTask<NSDictionary> {
        return AWSTask(result: tokens! as NSDictionary)
    }
}
