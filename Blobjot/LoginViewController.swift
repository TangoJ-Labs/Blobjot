//
//  LoginViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 9/19/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import FBSDKLoginKit
import UIKit

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    // The views to hold major components of the view controller
    var viewContainer: UIView!
    var statusBarView: UIView!
    
    var loginScreen: UIView!
    var loginBox: UIView!
    var fbLoginButton: FBSDKLoginButton!
    var loginActivityIndicator: UIActivityIndicatorView!
    var loginProcessLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = UIRectEdge.all
        
        // Hide the navigation controller
        if let navController = navigationController {
            navController.isNavigationBarHidden = true
        }
        
        // Record the status bar settings to adjust the view if needed
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        viewFrameY = self.view.frame.minY
        screenSize = UIScreen.main.bounds
        
        let vcHeight = screenSize.height - statusBarHeight
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: screenSize.width / 4, y: vcHeight / 4, width: screenSize.width / 2, height: vcHeight / 2))
        viewContainer.backgroundColor = UIColor.white
        self.view.addSubview(viewContainer)
        
        // Create the login screen, login box, and facebook login button
        // Create the login screen and facebook login button
        loginScreen = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        loginScreen.backgroundColor = Constants.Colors.standardBackgroundGrayTransparent
        
        loginBox = UIView(frame: CGRect(x: (loginScreen.frame.width / 2) - 140, y: (loginScreen.frame.height / 2) - 40, width: 280, height: 120))
        loginBox.layer.cornerRadius = 5
        loginBox.backgroundColor = Constants.Colors.standardBackground
        viewContainer.addSubview(loginBox)
        
        fbLoginButton = FBSDKLoginButton()
        fbLoginButton.center = CGPoint(x: loginBox.frame.width / 2, y: loginBox.frame.height / 2)
        fbLoginButton.readPermissions = ["public_profile", "email"]
        fbLoginButton.delegate = self
        loginBox.addSubview(fbLoginButton)
        
        // Add a loading indicator for the pause showing the "Log out" button after the FBSDK is logged in and before the Account VC loads
        loginActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: loginBox.frame.height / 2 + 15, width: loginBox.frame.width, height: 30))
        loginActivityIndicator.color = UIColor.black
        loginBox.addSubview(loginActivityIndicator)
        
        loginProcessLabel = UILabel(frame: CGRect(x: 0, y: loginBox.frame.height - 15, width: loginBox.frame.width, height: 14))
        loginProcessLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        loginProcessLabel.text = "Logging you in..."
        loginProcessLabel.textColor = UIColor.black
        loginProcessLabel.textAlignment = .center
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: FBSDK METHODS
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if ((error) != nil) {
            print("LVC - FBSDK ERROR: \(error)")
        }
        else if result.isCancelled {
            print("LVC - FBSDK IS CANCELLED: \(result.description)")
        }
        else {
            // Show the logging in indicator and label
            loginActivityIndicator.startAnimating()
            loginBox.addSubview(loginProcessLabel)
            
            // Set the new login indicator for certain settings
//            self.newLogin = true
        }
    }
    
    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool {
        print("LVC - FBSDK WILL LOG IN: \(loginButton)")
        return true
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("LVC - FBSDK DID LOG OUT: \(loginButton)")
        
        Constants.credentialsProvider.clearCredentials()
        Constants.credentialsProvider.clearKeychain()
    }

}
