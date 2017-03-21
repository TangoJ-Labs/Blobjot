//
//  LoginViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 9/19/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import UIKit
import DigitsKit
import ImageIO
import MobileCoreServices


class LoginViewController: UIViewController
{
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    
    // Declare the view components
    var viewContainer: UIView!
    var loginButton: UILabel!
    
    // Declare the variables
    var userID: String!
    var userPhoneNumber: String!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        addgradient()
        addViews()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    func addViews()
    {
        screenSize = UIScreen.main.bounds
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
        viewContainer.backgroundColor = UIColor.black
        self.view.addSubview(viewContainer)
        
        let loginButtonHeight: CGFloat = 80
        loginButton = UILabel(frame: CGRect(x: 0, y: viewContainer.frame.height - loginButtonHeight, width: viewContainer.frame.width, height: loginButtonHeight))
        loginButton.backgroundColor = UIColor(red: 14.0/255.0, green: 179.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        loginButton.textColor = UIColor.white
        loginButton.font = UIFont(name: "AvenirNext-Bold", size: 16)
        loginButton.clipsToBounds = true
        loginButton.textAlignment = .center
        loginButton.text = "SIGN UP WITH PHONE NUMBER"
        loginButton.isUserInteractionEnabled = true
        viewContainer.addSubview(loginButton)
        
        loginButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.auth)))
    }
    
    func addgradient()
    {
        self.view.backgroundColor = UIColor.clear
        
        let gradient: CAGradientLayer = CAGradientLayer()
        let colorTop = UIColor(red: 235.0/255.0, green: 66.0/255.0, blue: 148.0/255.0, alpha: 1.0)
        let colorBottom = UIColor(red: 14.0/255.0, green: 179.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        
        gradient.frame = self.view.bounds
        gradient.colors = [colorBottom.cgColor, colorTop.cgColor]
        gradient.locations = [0.2, 0.9]
        
        self.view.layer.insertSublayer(gradient, at: 0)
    }
    
    func auth()
    {
        UIApplication.shared.statusBarStyle = .default
        
        let digits = Digits.sharedInstance()
        digits.authenticate { (session, error) in
            
            // Inspect session/error objects
            if let thisSession = session
            {
                self.userPhoneNumber = thisSession.phoneNumber
                
                UIApplication.shared.statusBarStyle = .lightContent
                
                print("LVC - USER ID: \(thisSession.userID)")
                print("LVC - USER PHONE NUMBER: \(thisSession.phoneNumber)")
//                digits.logOut()
            }
            else
            {
                NSLog("Authentication error: %@", error!.localizedDescription)
            }
        }
    }
}
