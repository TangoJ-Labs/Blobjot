//
//  AccountViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 8/1/16.
//  Copyright © 2016 tangojlabs. All rights reserved.
//

import AWSLambda
import AWSS3
import FBSDKLoginKit
import GoogleMaps
import UIKit


// Create a protocol with functions declared in other View Controllers implementing this protocol (delegate)
protocol AccountViewControllerDelegate {
    
    // When called, the parent View Controller checks for changes to the logged in user
    func logoutUser()
    
    // When called, fire the parent popViewController
    func popViewController()
}

class AccountViewController: UIViewController, UITextViewDelegate, UISearchBarDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PeopleViewControllerDelegate, AWSRequestDelegate {
    
    // Add a delegate variable which the parent view controller can pass its own delegate instance to and have access to the protocol
    // (and have its own functions called that are listed in the protocol)
    var accountViewDelegate: AccountViewControllerDelegate?

    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    var viewContainer: UIView!
    var displayUserContainer: UIView!
    var displayUserImageContainer: UIView!
    var displayUserImageActivityIndicator: UIActivityIndicatorView!
    var displayUserImage: UIImageView!
    var displayUserLabel: UILabel!
//    var displayUserTextField: UITextField!
    var displayUserTextFieldActivityIndicator: UIActivityIndicatorView!
    
    var logoutButton: UIView!
    var logoutButtonLabel: UILabel!
    
    var peopleViewContainer: UIView!
    var displayUserEditNameView: UIView!
    var editNameCurrentName: UITextView!
    var editNameNewNameLabel: UILabel!
    var editNameNewName: UITextView!
    var editNameSaveButton: UIView!
    var editNameSaveButtonLabel: UILabel!
    var viewScreen: UIView!
    
    // Facebook Login
    var fbLoginButton: FBSDKLoginButton!
    
//    var cellPeopleTableViewTapGesture: UITapGestureRecognizer!
    var userImageTapGesture: UITapGestureRecognizer!
    var userNameTapGesture: UITapGestureRecognizer!
    var logoutButtonTapGesture: UITapGestureRecognizer!
    var editNameSaveButtonTapGesture: UITapGestureRecognizer!
    var viewScreenTapGesture: UITapGestureRecognizer!
    
    var currentUserName: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Status Bar Settings
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        navBarHeight = self.navigationController?.navigationBar.frame.height
        print("**************** AVC - NAV BAR HEIGHT: \(navBarHeight)")
        viewFrameY = self.view.frame.minY
        print("**************** AVC - VIEW FRAME Y: \(viewFrameY)")
        screenSize = UIScreen.main.bounds
        print("**************** AVC - SCREEN HEIGHT: \(screenSize.height)")
        print("**************** AVC - VIEW HEIGHT: \(self.view.frame.height)")
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: statusBarHeight + navBarHeight - viewFrameY, width: self.view.frame.width, height: self.view.frame.height - statusBarHeight - navBarHeight + viewFrameY))
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        self.view.addSubview(viewContainer)
        
        // Add the display User container to show above the people list and search bar
        displayUserContainer = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: Constants.Dim.accountProfileBoxHeight))
        displayUserContainer.backgroundColor = UIColor.clear
        viewContainer.addSubview(displayUserContainer)
        
        // Local User Account Box
        displayUserLabel = UILabel(frame: CGRect(x: 0, y: 95, width: viewContainer.frame.width / 2, height: 20))
        displayUserLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        displayUserLabel.textColor = Constants.Colors.colorTextGray
        displayUserLabel.textAlignment = NSTextAlignment.center
        displayUserLabel.isUserInteractionEnabled = true
//        displayUserTextField.returnKeyType = UIReturnKeyType.Done
//        displayUserTextField.delegate = self
        
        // Add a loading indicator while downloading the logged in user name
        displayUserTextFieldActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 90, width: viewContainer.frame.width / 2, height: 30))
        displayUserTextFieldActivityIndicator.color = UIColor.black
        
        displayUserImageContainer = UIView(frame: CGRect(x: (viewContainer.frame.width / 4) - 40, y: 5, width: 80, height: 80))
        displayUserImageContainer.layer.cornerRadius = displayUserImageContainer.frame.width / 2
        displayUserImageContainer.backgroundColor = UIColor.white
        displayUserImageContainer.layer.shadowOffset = CGSize(width: 0.5, height: 2)
        displayUserImageContainer.layer.shadowOpacity = 0.5
        displayUserImageContainer.layer.shadowRadius = 1.0
        
        // Add a loading indicator while downloading the logged in user image
        displayUserImageActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: displayUserImageContainer.frame.width, height: displayUserImageContainer.frame.height))
        displayUserImageActivityIndicator.color = UIColor.black
        
        displayUserImage = UIImageView(frame: CGRect(x: 0, y: 0, width: displayUserImageContainer.frame.width, height: displayUserImageContainer.frame.height))
        displayUserImage.layer.cornerRadius = displayUserImageContainer.frame.width / 2
        displayUserImage.contentMode = UIViewContentMode.scaleAspectFill
        displayUserImage.clipsToBounds = true
        displayUserImageContainer.addSubview(displayUserImage)
        
        // Try to retrieve the current user data from Core Data
        // Access Core Data
        // Retrieve the Current User Blob data from Core Data
        let moc = DataController().managedObjectContext
        let currentUserFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "CurrentUser")
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var currentUser = [CurrentUser]()
        do {
            currentUser = try moc.fetch(currentUserFetch) as! [CurrentUser]
        } catch {
            fatalError("Failed to fetch frames: \(error)")
        }
        
        // If the return has content, the current user is saved - use that data
        if currentUser.count > 0
        {
            print("CORE DATA - CURRENT USER - GOT USER DATA")
            
            // Apply the current user data in the current user elements
            displayUserLabel.text = currentUser[0].userName
            
            if let imageData = currentUser[0].userImage
            {
                displayUserImage.image = UIImage(data: imageData)
            }
        }
        
        // Add a custom logout button
        logoutButton = UIView(frame: CGRect(x: (viewContainer.frame.width * 3) / 4 - 50, y: displayUserContainer.frame.height / 2 - 30, width: 100, height: 60))
        logoutButton.layer.cornerRadius = 5
        logoutButton.backgroundColor = Constants.Colors.standardBackgroundGray
        
        logoutButtonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: logoutButton.frame.width, height: logoutButton.frame.height))
        logoutButtonLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        logoutButtonLabel.textColor = Constants.Colors.standardBackground
        logoutButtonLabel.textAlignment = NSTextAlignment.center
        logoutButtonLabel.text = "Log Out"
        logoutButton.addSubview(logoutButtonLabel)
        
        if Constants.Data.currentUser != "" {
            displayUserContainer.addSubview(displayUserLabel)
            displayUserContainer.addSubview(displayUserTextFieldActivityIndicator)
            displayUserTextFieldActivityIndicator.startAnimating()
            displayUserContainer.addSubview(displayUserImageContainer)
            displayUserImageContainer.addSubview(displayUserImageActivityIndicator)
            displayUserImageActivityIndicator.startAnimating()
            displayUserContainer.addSubview(logoutButton)
        }
        
        peopleViewContainer = UIView(frame: CGRect(x: 0, y: Constants.Dim.accountProfileBoxHeight, width: viewContainer.frame.width, height: viewContainer.frame.height - Constants.Dim.accountProfileBoxHeight))
        viewContainer.addSubview(peopleViewContainer)
        
        let peopleViewController = PeopleViewController()
        peopleViewController.peopleViewDelegate = self
        peopleViewController.useBarHeights = false
        peopleViewController.printCheck = "CHILD"
        addChildViewController(peopleViewController)
        print("AVC - PEOPLE VIEW CONTAINER: \(peopleViewContainer.frame)")
        peopleViewController.view.frame = CGRect(x: 0, y: 0, width: peopleViewContainer.frame.width, height: peopleViewContainer.frame.height)
        peopleViewContainer.addSubview(peopleViewController.view)
        peopleViewController.didMove(toParentViewController: self)
        
        viewScreen = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        viewScreen.backgroundColor = Constants.Colors.standardBackgroundGrayTransparent
        
        displayUserEditNameView = UIView(frame: CGRect(x: 50, y: viewContainer.frame.height, width: viewContainer.frame.width - 100, height: 200))
        displayUserEditNameView.layer.cornerRadius = 5
        displayUserEditNameView.backgroundColor = Constants.Colors.standardBackground
        displayUserEditNameView.layer.shadowOffset = CGSize(width: 0.5, height: 2)
        displayUserEditNameView.layer.shadowOpacity = 0.5
        displayUserEditNameView.layer.shadowRadius = 1.0
        
        editNameCurrentName = UITextView(frame: CGRect(x: 10, y: 10, width: displayUserEditNameView.frame.width - 20, height: 50))
        editNameCurrentName.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        editNameCurrentName.text = "Current User Name:"
        editNameCurrentName.textColor = Constants.Colors.colorTextGray
        editNameCurrentName.textAlignment = NSTextAlignment.center
        editNameCurrentName.isUserInteractionEnabled = false
        displayUserEditNameView.addSubview(editNameCurrentName)
        
        editNameNewNameLabel = UILabel(frame: CGRect(x: 10, y: 75, width: displayUserEditNameView.frame.width - 20, height: 20))
        editNameNewNameLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        editNameNewNameLabel.text = "New Name:"
        editNameNewNameLabel.textColor = Constants.Colors.colorTextGray
        editNameNewNameLabel.textAlignment = NSTextAlignment.center
        displayUserEditNameView.addSubview(editNameNewNameLabel)
        
        editNameNewName = UITextView(frame: CGRect(x: 10, y: 100, width: displayUserEditNameView.frame.width - 20, height: 26))
        editNameNewName.layer.borderWidth = 2
        editNameNewName.layer.borderColor = Constants.Colors.standardBackgroundGray.cgColor
        editNameNewName.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        editNameNewName.textColor = Constants.Colors.colorTextGray
        editNameNewName.text = ""
        editNameNewName.textAlignment = NSTextAlignment.center
        editNameNewName.isUserInteractionEnabled = true
        editNameNewName.returnKeyType = UIReturnKeyType.done
        editNameNewName.delegate = self
        displayUserEditNameView.addSubview(editNameNewName)
        
        let editNameSaveButtonHeight: CGFloat = 50
        editNameSaveButton = UIView(frame: CGRect(x: 0, y: displayUserEditNameView.frame.height - editNameSaveButtonHeight, width: displayUserEditNameView.frame.width, height: editNameSaveButtonHeight))
        let cornerShape = CAShapeLayer()
        cornerShape.bounds = editNameSaveButton.frame
        cornerShape.position = editNameSaveButton.center
        cornerShape.path = UIBezierPath(roundedRect: editNameSaveButton.bounds, byRoundingCorners: [UIRectCorner.bottomLeft , UIRectCorner.bottomRight], cornerRadii: CGSize(width: 5, height: 5)).cgPath
        editNameSaveButton.layer.mask = cornerShape
        editNameSaveButton.backgroundColor = Constants.Colors.blobPurpleOpaque
        displayUserEditNameView.addSubview(editNameSaveButton)
        
        editNameSaveButtonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: editNameSaveButton.frame.width, height: editNameSaveButtonHeight))
        editNameSaveButtonLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        editNameSaveButtonLabel.text = "SAVE"
        editNameSaveButtonLabel.textColor = UIColor.white
        editNameSaveButtonLabel.textAlignment = NSTextAlignment.center
        editNameSaveButton.addSubview(editNameSaveButtonLabel)
        
        userImageTapGesture = UITapGestureRecognizer(target: self, action: #selector(AccountViewController.imageTapGesture(_:)))
        userImageTapGesture.numberOfTapsRequired = 1  // add single tap
        displayUserImageContainer.addGestureRecognizer(userImageTapGesture)
        
        userNameTapGesture = UITapGestureRecognizer(target: self, action: #selector(AccountViewController.userNameTapGesture(_:)))
        userNameTapGesture.numberOfTapsRequired = 1  // add single tap
        displayUserLabel.addGestureRecognizer(userNameTapGesture)
        
        logoutButtonTapGesture = UITapGestureRecognizer(target: self, action: #selector(AccountViewController.logoutButtonTapGesture(_:)))
        logoutButtonTapGesture.numberOfTapsRequired = 1  // add single tap
        logoutButton.addGestureRecognizer(logoutButtonTapGesture)
        
        editNameSaveButtonTapGesture = UITapGestureRecognizer(target: self, action: #selector(AccountViewController.editNameSaveButtonTapGesture(_:)))
        editNameSaveButtonTapGesture.numberOfTapsRequired = 1  // add single tap
        editNameSaveButton.addGestureRecognizer(editNameSaveButtonTapGesture)
        
        viewScreenTapGesture = UITapGestureRecognizer(target: self, action: #selector(AccountViewController.viewScreenTapGesture(_:)))
        viewScreenTapGesture.numberOfTapsRequired = 1  // add single tap
        viewScreen.addGestureRecognizer(viewScreenTapGesture)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: GESTURE RECOGNIZERS
    
    // Reveal the popup screen to edit the userName
    func viewScreenTapGesture(_ sender: UITapGestureRecognizer) {
        print("VIEW SCREEN TAPPED - REMOVE SCREEN")
        
        hideScreenAndEditNameBox()
    }
    
    func hideScreenAndEditNameBox() {
        // Remove the gray screen
        self.viewScreen.removeFromSuperview()
        
        // Animate the user name edit popup out of view
        UIView.animate(withDuration: 0.2, animations: {
            self.displayUserEditNameView.frame = CGRect(x: 50, y: self.viewContainer.frame.height, width: self.viewContainer.frame.width - 100, height: self.viewContainer.frame.width - 50)
            }, completion: { (finished: Bool) -> Void in
                self.displayUserEditNameView.removeFromSuperview()
        })
    }
    
    // Reveal the popup screen to edit the userName
    func userNameTapGesture(_ sender: UITapGestureRecognizer) {
        print("EDIT USER NAME: \(currentUserName)")
        
        // Show the gray screen to highlight the name editor popup
        self.viewContainer.addSubview(viewScreen)
        self.viewContainer.addSubview(displayUserEditNameView)
        
        DispatchQueue.main.async(execute: {
            self.editNameCurrentName.text = "Current User Name:\n " + self.currentUserName
        })
        
        // Add an animation to bring the edit user name screen into view
        UIView.animate(withDuration: 0.2, animations: {
            self.displayUserEditNameView.frame = CGRect(x: 50, y: 50, width: self.viewContainer.frame.width - 100, height: 200)
            }, completion: nil)
    }
    
    // Log out the user from the app and facebook
    func logoutButtonTapGesture(_ sender: UITapGestureRecognizer) {
        print("TRYING TO LOG OUT THE USER")
        
        // Log out the user from Facebook
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        
        // Log out the user from the app
        Constants.Data.currentUser = ""
        
        // Clear the data from the app
        Constants.Data.mapBlobs = [Blob]()
        Constants.Data.userBlobs = [Blob]()
        Constants.Data.locationBlobs = [Blob]()
        Constants.Data.blobThumbnailObjects = [BlobThumbnailObject]()
        Constants.Data.userObjects = [User]()
        
        for circle in Constants.Data.mapCircles {
            circle.map = nil
        }
        Constants.Data.mapCircles = [GMSCircle]()
        
        // Call the parent VC to remove the current VC from the stack
        if let parentVC = self.accountViewDelegate {
            parentVC.popViewController()
            parentVC.logoutUser()
        }
        
//        // Load the Map View and show the login screen
//        self.popViewController()
    }
    
    // Save the newly typed user name
    func editNameSaveButtonTapGesture(_ sender: UITapGestureRecognizer) {
        print("TRYING TO SAVE NEW USER NAME")
        
        // Save the userName to AWS and show in the display user label
        if let newUserName = self.editNameNewName.text {
            
            // Ensure that the new username is not blank
            if newUserName != "" {
                
                // Close the keyboard and hide the screen and edit name box
                self.view.endEditing(true)
                self.hideScreenAndEditNameBox()
                
                // Show the new name in the display user label
                self.displayUserLabel.text = newUserName
                
                // Upload the new username to AWS
                AWSPrepRequest(requestToCall: AWSEditUserName(newUserName: newUserName), delegate: self as AWSRequestDelegate).prepRequest()
                
                // Edit the logged in user's userName in the global list
                userLoop: for userObject in Constants.Data.userObjects {
                    if userObject.userID == Constants.Data.currentUser {
                        userObject.userName = newUserName
                        break userLoop
                    }
                }
            }
        }
    }
    
    // Update the User Image using a media picker
    func imageTapGesture(_ sender: UITapGestureRecognizer) {
        print("LOAD IMAGE SELECTOR VC")
        
        // Show the gray screen to indicate that the picker is loading
        viewContainer.addSubview(viewScreen)
        
        // Load the image picker - allow only photos
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    // ImagePicker Delegate Methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print("you picked: \(info)")
        
        // Remove the gray screen
        self.viewScreen.removeFromSuperview()
        
        // Process the picked image
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            // Assign the new image to the local userImage view
            displayUserImage.image = pickedImage
            
            // Update the global userObject with the new image
            loopUserObjectCheck: for userObject in Constants.Data.userObjects {
                if userObject.userID == Constants.Data.currentUser {
                    userObject.userImage = pickedImage
                    
                    break loopUserObjectCheck
                }
            }
            
            // Upload the new user image to AWS and update the userImageKey
            AWSPrepRequest(requestToCall: AWSEditUserImage(newUserImage: pickedImage), delegate: self as AWSRequestDelegate).prepRequest()
        }
        self.dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        // Remove the gray screen
        self.viewScreen.removeFromSuperview()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: CUSTOM FUNCTIONS
    
    func popViewController(_ sender: UIBarButtonItem? = nil) {
        print("pop Back to Map View")
        self.dismiss(animated: true, completion: {
        })
    }
    
    // The Child View Controller will call this function when the logged in user has been added to the global user list
    func userObjectListUpdatedWithCurrentUser() {
        
        // Find the logged in User Object in the global User list and use the data to fill out the user display views
        userLoop: for userObject in Constants.Data.userObjects {
            print("GLOBAL LIST USER CHECK: \(userObject.userName)")
            
            if userObject.userID == Constants.Data.currentUser {
                print("IN PARENT - GOT CURRENT USER: \(userObject.userName)")
                
                // Show the logged in user's username in the display user label
                currentUserName  = userObject.userName
                displayUserLabel.text = userObject.userName
                displayUserTextFieldActivityIndicator.stopAnimating()
                
                // Check to see if the current user data is already in Core Data
                // Access Core Data
                // Retrieve the Current User Blob data from Core Data
                let moc = DataController().managedObjectContext
                let currentUserFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "CurrentUser")
                
                // Create an empty blobNotifications list in case the Core Data request fails
                var currentUser = [CurrentUser]()
                do {
                    currentUser = try moc.fetch(currentUserFetch) as! [CurrentUser]
                } catch {
                    fatalError("Failed to fetch frames: \(error)")
                }
                
                print("CHECKING CORE DATA - CURRENT USER COUNT: \(currentUser.count)")
                
                // If the return has no content, the current user has not yet been saved
                if currentUser.count == 0 {
                    print("CHECKING CORE DATA - NO CURRENT USER DATA - CALLING GET USER DATA")
                    
                    // Download the user's userImage and display in the display user image view
                    AWSPrepRequest(requestToCall: AWSGetUserImage(user: userObject), delegate: self as AWSRequestDelegate).prepRequest()
                    
                } else {
                    print("CHECKING CORE DATA - USE PREVIOUS IMAGE DATA")
                    
                    // Else use the saved current user data until the data is updated
                    if let imageData = currentUser[0].userImage {
                        print("CHECKING CORE DATA - PREVIOUS IMAGE DATA EXISTS")
                        self.displayUserImage.image = UIImage(data: imageData as Data)
                        self.displayUserImageActivityIndicator.stopAnimating()
                    }
                }
                
                break userLoop
            }
        }
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen() {
        print("AD - SHOW LOGIN SCREEN")
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
        DispatchQueue.main.async(execute:
            {
                // Process the return data based on the method used
                switch objectType
                {
                case let awsGetUserImage as AWSGetUserImage:
                    if success
                    {
                        // Refresh the user image if it exists
                        if let userImage = awsGetUserImage.user.userImage
                        {
                            self.displayUserImage.image = userImage
                            self.displayUserImageActivityIndicator.stopAnimating()
                            print("ADDED IMAGE TO DISPLAY USER IMAGE: \(awsGetUserImage.user.userImageKey))")
                            
                            // Store the new image in Core Data for immediate access in next VC loading
                            self.saveUserImageToCoreData(user: awsGetUserImage.user)
                        }
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case _ as AWSEditUserName:
                    if !success
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case _ as AWSEditUserImage:
                    if !success
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                default:
                    print("DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    
                    // Show the error message
                    let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    self.present(alertController, animated: true, completion: nil)
                }
        })
    }
    
    // Save the current user's image to Core Data
    func saveUserImageToCoreData(user: User)
    {
        // Access Core Data
        // Retrieve the Current User Blob data from Core Data
        let moc = DataController().managedObjectContext
        let currentUserFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "CurrentUser")
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var currentUser = [CurrentUser]()
        do {
            currentUser = try moc.fetch(currentUserFetch) as! [CurrentUser]
        } catch {
            fatalError("Failed to fetch frames: \(error)")
        }
        
        print("CORE DATA - CURRENT USER COUNT: \(currentUser.count)")
        
        // If the return has no content, the current user has not yet been saved
        if currentUser.count == 0 {
            print("CORE DATA - CURRENT USER - SAVING NEW DATA")
            
            // Save the current user data in Core Data
            let entity = NSEntityDescription.insertNewObject(forEntityName: "CurrentUser", into: moc) as! CurrentUser
            entity.setValue(user.userID, forKey: "userID")
            entity.setValue(user.userName, forKey: "userName")
            entity.setValue(user.userImageKey, forKey: "userImageKey")
            if let userImage = user.userImage
            {
                entity.setValue(UIImagePNGRepresentation(userImage), forKey: "userImage")
            }
        } else {
            print("CORE DATA - CURRENT USER - MODIFYING DATA")
            
            // Replace the current user data to ensure that the latest data is used
            currentUser[0].userID = user.userID
            currentUser[0].userName = user.userName
            currentUser[0].userImageKey = user.userImageKey
            currentUser[0].userImage = UIImagePNGRepresentation(user.userImage!)
        }
        
        // Save the Entity
        do {
            try moc.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
    }

}
