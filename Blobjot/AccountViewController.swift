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
    func checkForUser()
    
    // When called, fire the parent popViewController
    func popViewController()
}

class AccountViewController: UIViewController, UITextViewDelegate, UISearchBarDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PeopleViewControllerDelegate {
    
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
        UIApplication.sharedApplication().statusBarHidden = false
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        statusBarHeight = UIApplication.sharedApplication().statusBarFrame.size.height
        navBarHeight = self.navigationController?.navigationBar.frame.height
        print("**************** AVC - NAV BAR HEIGHT: \(navBarHeight)")
        viewFrameY = self.view.frame.minY
        print("**************** AVC - VIEW FRAME Y: \(viewFrameY)")
        screenSize = UIScreen.mainScreen().bounds
        print("**************** AVC - SCREEN HEIGHT: \(screenSize.height)")
        print("**************** AVC - VIEW HEIGHT: \(self.view.frame.height)")
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: statusBarHeight + navBarHeight - viewFrameY, width: self.view.frame.width, height: self.view.frame.height - statusBarHeight - navBarHeight + viewFrameY))
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        self.view.addSubview(viewContainer)
        
        // Add the display User container to show above the people list and search bar
        displayUserContainer = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: Constants.Dim.accountProfileBoxHeight))
        displayUserContainer.backgroundColor = UIColor.clearColor()
        viewContainer.addSubview(displayUserContainer)
        
        // Local User Account Box
        displayUserLabel = UILabel(frame: CGRect(x: 0, y: 95, width: viewContainer.frame.width / 2, height: 20))
        displayUserLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        displayUserLabel.textColor = Constants.Colors.colorTextGray
        displayUserLabel.textAlignment = NSTextAlignment.Center
        displayUserLabel.userInteractionEnabled = true
//        displayUserTextField.returnKeyType = UIReturnKeyType.Done
//        displayUserTextField.delegate = self
        
        // Add a loading indicator while downloading the logged in user name
        displayUserTextFieldActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 90, width: viewContainer.frame.width / 2, height: 30))
        displayUserTextFieldActivityIndicator.color = UIColor.blackColor()
        
        displayUserImageContainer = UIView(frame: CGRect(x: (viewContainer.frame.width / 4) - 40, y: 5, width: 80, height: 80))
        displayUserImageContainer.layer.cornerRadius = displayUserImageContainer.frame.width / 2
        displayUserImageContainer.backgroundColor = UIColor.whiteColor()
        displayUserImageContainer.layer.shadowOffset = CGSizeMake(0.5, 2)
        displayUserImageContainer.layer.shadowOpacity = 0.5
        displayUserImageContainer.layer.shadowRadius = 1.0
        
        // Add a loading indicator while downloading the logged in user image
        displayUserImageActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: displayUserImageContainer.frame.width, height: displayUserImageContainer.frame.height))
        displayUserImageActivityIndicator.color = UIColor.blackColor()
        
        displayUserImage = UIImageView(frame: CGRect(x: 0, y: 0, width: displayUserImageContainer.frame.width, height: displayUserImageContainer.frame.height))
        displayUserImage.layer.cornerRadius = displayUserImageContainer.frame.width / 2
        displayUserImage.contentMode = UIViewContentMode.ScaleAspectFill
        displayUserImage.clipsToBounds = true
        displayUserImageContainer.addSubview(displayUserImage)
        
        // Add a custom logout button
        logoutButton = UIView(frame: CGRect(x: (viewContainer.frame.width * 3) / 4 - 50, y: displayUserContainer.frame.height / 2 - 30, width: 100, height: 60))
        logoutButton.layer.cornerRadius = 5
        logoutButton.backgroundColor = Constants.Colors.standardBackgroundGray
        
        logoutButtonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: logoutButton.frame.width, height: logoutButton.frame.height))
        logoutButtonLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        logoutButtonLabel.textColor = Constants.Colors.standardBackground
        logoutButtonLabel.textAlignment = NSTextAlignment.Center
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
        peopleViewController.didMoveToParentViewController(self)
        
        viewScreen = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        viewScreen.backgroundColor = Constants.Colors.standardBackgroundGrayTransparent
        
        displayUserEditNameView = UIView(frame: CGRect(x: 50, y: viewContainer.frame.height, width: viewContainer.frame.width - 100, height: 200))
        displayUserEditNameView.layer.cornerRadius = 5
        displayUserEditNameView.backgroundColor = Constants.Colors.standardBackground
        displayUserEditNameView.layer.shadowOffset = CGSizeMake(0.5, 2)
        displayUserEditNameView.layer.shadowOpacity = 0.5
        displayUserEditNameView.layer.shadowRadius = 1.0
        
        editNameCurrentName = UITextView(frame: CGRect(x: 10, y: 10, width: displayUserEditNameView.frame.width - 20, height: 50))
        editNameCurrentName.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        editNameCurrentName.text = "Current User Name:"
        editNameCurrentName.textColor = Constants.Colors.colorTextGray
        editNameCurrentName.textAlignment = NSTextAlignment.Center
        editNameCurrentName.userInteractionEnabled = false
        displayUserEditNameView.addSubview(editNameCurrentName)
        
        editNameNewNameLabel = UILabel(frame: CGRect(x: 10, y: 75, width: displayUserEditNameView.frame.width - 20, height: 20))
        editNameNewNameLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        editNameNewNameLabel.text = "New Name:"
        editNameNewNameLabel.textColor = Constants.Colors.colorTextGray
        editNameNewNameLabel.textAlignment = NSTextAlignment.Center
        displayUserEditNameView.addSubview(editNameNewNameLabel)
        
        editNameNewName = UITextView(frame: CGRect(x: 10, y: 100, width: displayUserEditNameView.frame.width - 20, height: 26))
        editNameNewName.layer.borderWidth = 2
        editNameNewName.layer.borderColor = Constants.Colors.standardBackgroundGray.CGColor
        editNameNewName.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        editNameNewName.textColor = Constants.Colors.colorTextGray
        editNameNewName.text = ""
        editNameNewName.textAlignment = NSTextAlignment.Center
        editNameNewName.userInteractionEnabled = true
        editNameNewName.returnKeyType = UIReturnKeyType.Done
        editNameNewName.delegate = self
        displayUserEditNameView.addSubview(editNameNewName)
        
        let editNameSaveButtonHeight: CGFloat = 50
        editNameSaveButton = UIView(frame: CGRect(x: 0, y: displayUserEditNameView.frame.height - editNameSaveButtonHeight, width: displayUserEditNameView.frame.width, height: editNameSaveButtonHeight))
        let cornerShape = CAShapeLayer()
        cornerShape.bounds = editNameSaveButton.frame
        cornerShape.position = editNameSaveButton.center
        cornerShape.path = UIBezierPath(roundedRect: editNameSaveButton.bounds, byRoundingCorners: [UIRectCorner.BottomLeft , UIRectCorner.BottomRight], cornerRadii: CGSize(width: 5, height: 5)).CGPath
        editNameSaveButton.layer.mask = cornerShape
        editNameSaveButton.backgroundColor = Constants.Colors.blobPurpleOpaque
        displayUserEditNameView.addSubview(editNameSaveButton)
        
        editNameSaveButtonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: editNameSaveButton.frame.width, height: editNameSaveButtonHeight))
        editNameSaveButtonLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        editNameSaveButtonLabel.text = "SAVE"
        editNameSaveButtonLabel.textColor = UIColor.whiteColor()
        editNameSaveButtonLabel.textAlignment = NSTextAlignment.Center
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
    func viewScreenTapGesture(sender: UITapGestureRecognizer) {
        print("VIEW SCREEN TAPPED - REMOVE SCREEN")
        
        hideScreenAndEditNameBox()
    }
    
    func hideScreenAndEditNameBox() {
        // Remove the gray screen
        self.viewScreen.removeFromSuperview()
        
        // Animate the user name edit popup out of view
        UIView.animateWithDuration(0.2, animations: {
            self.displayUserEditNameView.frame = CGRect(x: 50, y: self.viewContainer.frame.height, width: self.viewContainer.frame.width - 100, height: self.viewContainer.frame.width - 50)
            }, completion: { (finished: Bool) -> Void in
                self.displayUserEditNameView.removeFromSuperview()
        })
    }
    
    // Reveal the popup screen to edit the userName
    func userNameTapGesture(sender: UITapGestureRecognizer) {
        print("EDIT USER NAME: \(currentUserName)")
        
        // Show the gray screen to highlight the name editor popup
        self.viewContainer.addSubview(viewScreen)
        self.viewContainer.addSubview(displayUserEditNameView)
        
        dispatch_async(dispatch_get_main_queue(), {
            self.editNameCurrentName.text = "Current User Name:\n " + self.currentUserName
        });
        
        // Add an animation to bring the edit user name screen into view
        UIView.animateWithDuration(0.2, animations: {
            self.displayUserEditNameView.frame = CGRect(x: 50, y: 50, width: self.viewContainer.frame.width - 100, height: 200)
            }, completion: nil)
    }
    
    // Log out the user from the app and facebook
    func logoutButtonTapGesture(sender: UITapGestureRecognizer) {
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
            parentVC.checkForUser()
            parentVC.popViewController()
        }
        
//        // Load the Map View and show the login screen
//        self.popViewController()
    }
    
    // Save the newly typed user name
    func editNameSaveButtonTapGesture(sender: UITapGestureRecognizer) {
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
                editUserName(Constants.Data.currentUser, userName: newUserName)
                
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
    func imageTapGesture(sender: UITapGestureRecognizer) {
        print("LOAD IMAGE SELECTOR VC")
        
        // Show the gray screen to indicate that the picker is loading
        viewContainer.addSubview(viewScreen)
        
        // Load the image picker - allow only photos
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    // ImagePicker Delegate Methods
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        print("you picked: \(info)")
        
        // Remove the gray screen
        self.viewScreen.removeFromSuperview()
        
        // Process the picked image
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            // Assign the new image to the local userImage view
            displayUserImage.image = pickedImage
            
            // Upload the new user image to AWS and update the userImageKey
            updateUserImage(pickedImage)
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        
        // Remove the gray screen
        self.viewScreen.removeFromSuperview()
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: CUSTOM FUNCTIONS
    
    func popViewController(sender: UIBarButtonItem? = nil) {
        print("pop Back to Map View")
        self.dismissViewControllerAnimated(true, completion: {
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
                
                // Download the user's userImage and display in the display user image view
                getUserImage(userObject.userID, imageKey: userObject.userImageKey)
                displayUserImageActivityIndicator.stopAnimating()
                
                break userLoop
            }
        }
    }
    
    // Create a thumbnail-sized image from a large image
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSizeMake(size.width * heightRatio, size.height * heightRatio)
        } else {
            newSize = CGSizeMake(size.width * widthRatio,  size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRectMake(0, 0, newSize.width, newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.drawInRect(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
    // MARK: AWS METHODS
    
    // Edit the logged in user's userName
    func editUserName(userID: String, userName: String) {
        let json: NSDictionary = ["user_id" : userID, "user_name": userName]
        print("EDITING USER NAME TO: \(json)")
        
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        lambdaInvoker.invokeFunction("Blobjot-EditUserName", JSONObject: json, completionHandler: { (responseData, err) -> Void in
            
            if (err != nil) {
                print("Error: \(err)")
            } else if (responseData != nil) {
                print("EDIT USER NAME RESPONSE: \(responseData)")
            }
            
        })
    }
    
    // Download the userImage for the indicated user object in the UserObject list
    func updateUserImage(userImage: UIImage) {
        // Get the User Data for the userID
        let json: NSDictionary = ["request" : "random_user_image_id"]
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        lambdaInvoker.invokeFunction("Blobjot-CreateRandomID", JSONObject: json, completionHandler: { (responseData, err) -> Void in
            
            if (err != nil) {
                print("UUI: Error: \(err)")
            } else if (responseData != nil) {
                let imageID = responseData! as! String
                print("UUI: imageID: \(imageID)")
                
                let resizedImage = self.resizeImage(userImage, targetSize: CGSize(width: 200, height: 200))
                
                if let data = UIImagePNGRepresentation(resizedImage) {
                    print("UUI: INSIDE DATA")
                    
                    let filePath = NSTemporaryDirectory().stringByAppendingString("userImage" + imageID + ".png")
                    print("UUI: FILE PATH: \("file:///" + filePath)")
                    data.writeToFile(filePath, atomically: true)
                    
                    var uploadMetadata = [String : String]()
                    uploadMetadata["user_id"] = Constants.Data.currentUser
                    print("UUI: METADATA: \(uploadMetadata)")
                    
                    let uploadRequest = AWSS3TransferManagerUploadRequest()
                    uploadRequest.bucket = Constants.Strings.S3BucketUserImages
                    uploadRequest.metadata = uploadMetadata
                    uploadRequest.key =  imageID
                    uploadRequest.body = NSURL(string: "file:///" + filePath)
                    print("UUI: UPLOAD REQUEST: \(uploadRequest)")
                    
                    let transferManager = AWSS3TransferManager.defaultS3TransferManager()
                    transferManager.upload(uploadRequest).continueWithBlock({ (task) -> AnyObject! in
                        if let error = task.error {
                            if error.domain == AWSS3TransferManagerErrorDomain as String
                                && AWSS3TransferManagerErrorType(rawValue: error.code) == AWSS3TransferManagerErrorType.Paused {
                                print("Upload paused.")
                            } else {
                                print("Upload failed: [\(error)]")
                                // Delete the user image from temporary memory
                                do {
                                    print("Deleting image: \(imageID)")
                                    try NSFileManager.defaultManager().removeItemAtPath(filePath)
                                }
                                catch let error as NSError {
                                    print("Ooops! Something went wrong: \(error)")
                                }
                            }
                        } else if let exception = task.exception {
                            print("Upload failed: [\(exception)]")
                            // Delete the user image from temporary memory
                            do {
                                print("Deleting image: \(imageID)")
                                try NSFileManager.defaultManager().removeItemAtPath(filePath)
                            }
                            catch let error as NSError {
                                print("Ooops! Something went wrong: \(error)")
                            }
                        } else {
                            print("Upload succeeded")
                            // Delete the user image from temporary memory
                            do {
                                print("Deleting image: \(imageID)")
                                try NSFileManager.defaultManager().removeItemAtPath(filePath)
                            }
                            catch let error as NSError {
                                print("Ooops! Something went wrong: \(error)")
                            }
                        }
                        return nil
                    })
                }
            }
        })
    }
    
    // Download Logged In User Image
    func getUserImage(userID: String, imageKey: String) {
        print("AVC - GETTING IMAGE FOR: \(imageKey)")
        
        let downloadingFilePath = NSTemporaryDirectory().stringByAppendingString(imageKey) // + Constants.Settings.frameImageFileType)
        let downloadingFileURL = NSURL(fileURLWithPath: downloadingFilePath)
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        
        // Download the Frame
        let downloadRequest : AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.bucket = Constants.Strings.S3BucketUserImages
        downloadRequest.key =  imageKey
        downloadRequest.downloadingFileURL = downloadingFileURL
        
        transferManager.download(downloadRequest).continueWithBlock({ (task) -> AnyObject! in
            if let error = task.error {
                if error.domain == AWSS3TransferManagerErrorDomain as String
                    && AWSS3TransferManagerErrorType(rawValue: error.code) == AWSS3TransferManagerErrorType.Paused {
                    print("AVC - DOWNLOAD PAUSED")
                } else {
                    print("AVC - DOWNLOAD FAILED: [\(error)]")
                }
            } else if let exception = task.exception {
                print("AVC - DOWNLOAD FAILED: [\(exception)]")
            } else {
                print("AVC - DOWNLOAD SUCCEEDED")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    // Assign the image to the Preview Image View
                    if NSFileManager().fileExistsAtPath(downloadingFilePath) {
                        print("IMAGE FILE AVAILABLE")
                        let thumbnailData = NSData(contentsOfFile: downloadingFilePath)
                        
                        // Ensure the Thumbnail Data is not null
                        if let tData = thumbnailData {
                            print("GET IMAGE - CHECK 1")
                            
                            self.displayUserImage.image = UIImage(data: tData)
                            
                            print("ADDED IMAGE TO DISPLAY USER IMAGE: \(imageKey))")
                        }
                        
                    } else {
                        print("FRAME FILE NOT AVAILABLE")
                    }
                })
            }
            return nil
        })
    }

}
