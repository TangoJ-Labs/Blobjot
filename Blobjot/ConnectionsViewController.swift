//
//  ConnectionsViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 8/1/16.
//  Copyright © 2016 tangojlabs. All rights reserved.
//

import AWSLambda
import AWSS3
import UIKit


// Create a protocol with functions declared in other View Controllers implementing this protocol (delegate)
protocol ConnectionsViewControllerDelegate
{
    // When called, the parent View Controller checks for changes to the logged in user
    func logoutUser()
    
    // When called, fire the parent popViewController
    func popViewController()
}

class ConnectionsViewController: UIViewController, UISearchBarDelegate, AWSRequestDelegate
{
    
    // Add a delegate variable which the parent view controller can pass its own delegate instance to and have access to the protocol
    // (and have its own functions called that are listed in the protocol)
    var connectionsViewDelegate: ConnectionsViewControllerDelegate?

    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    var viewContainer: UIView!
    
    var peopleViewContainer: UIView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Status Bar Settings
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        navBarHeight = self.navigationController?.navigationBar.frame.height
        viewFrameY = self.view.frame.minY
        screenSize = UIScreen.main.bounds
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: statusBarHeight + navBarHeight - viewFrameY, width: self.view.frame.width, height: self.view.frame.height - statusBarHeight - navBarHeight + viewFrameY))
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        self.view.addSubview(viewContainer)
        
        peopleViewContainer = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height - navBarHeight - 49))
        viewContainer.addSubview(peopleViewContainer)
        
        let peopleViewController = PeopleViewController()
//        peopleViewController.peopleViewDelegate = self
        peopleViewController.useBarHeights = false
        peopleViewController.printCheck = "CHILD"
        addChildViewController(peopleViewController)
        print("CVC - PEOPLE VIEW CONTAINER: \(peopleViewContainer.frame)")
        peopleViewController.view.frame = CGRect(x: 0, y: 0, width: peopleViewContainer.frame.width, height: peopleViewContainer.frame.height)
        peopleViewContainer.addSubview(peopleViewController.view)
        peopleViewController.didMove(toParentViewController: self)
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: CUSTOM FUNCTIONS
    
    func popViewController(_ sender: UIBarButtonItem? = nil)
    {
        print("pop Back to Map View")
        self.dismiss(animated: true, completion:
            {
        })
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("AD - SHOW LOGIN SCREEN")
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
        DispatchQueue.main.async(execute:
            {
                // Process the return data based on the method used
                switch objectType
                {
                
                default:
                    print("AVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    
                    // Show the error message
                    let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    self.present(alertController, animated: true, completion: nil)
                }
        })
    }

}
