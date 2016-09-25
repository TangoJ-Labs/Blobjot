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
        });
        
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
                AWSPrepRequest(requestToCall: AWSEditUserName(userID: Constants.Data.currentUser, newUserName: newUserName), delegate: self as AWSRequestDelegate).prepRequest()
                
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
            updateUserImage(pickedImage)
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
                    getUserImage(userObject.userID, imageKey: userObject.userImageKey)
                    
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
    
    // Create a thumbnail-sized image from a large image
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen() {
        print("AD - SHOW LOGIN SCREEN")
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
        // Process the return data based on the method used
        switch objectType
        {
        case _ as AWSEditUserName:
            if !success
            {
                // Show the error message
//                self.createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try to update your username again.")
            }
        default:
            print("DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
            
            // Show the error message
//            self.createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
        }
    }
    
    // MARK: AWS METHODS
    
    // Download the userImage for the indicated user object in the UserObject list
    func updateUserImage(_ userImage: UIImage) {
        // Get the User Data for the userID
        let json: NSDictionary = ["request" : "random_user_image_id"]
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-CreateRandomID", jsonObject: json, completionHandler: { (responseData, err) -> Void in
            
            if (err != nil) {
                print("UUI: Error: \(err)")
            } else if (responseData != nil) {
                let imageID = responseData! as! String
                print("UUI: imageID: \(imageID)")
                
                let resizedImage = self.resizeImage(userImage, targetSize: CGSize(width: 200, height: 200))
                
                if let data = UIImagePNGRepresentation(resizedImage) {
                    print("UUI: INSIDE DATA")
                    
                    let filePath = NSTemporaryDirectory() + ("userImage" + imageID + ".png")
                    print("UUI: FILE PATH: \("file:///" + filePath)")
                    try? data.write(to: URL(fileURLWithPath: filePath), options: [.atomic])
                    
                    var uploadMetadata = [String : String]()
                    uploadMetadata["user_id"] = Constants.Data.currentUser
                    print("UUI: METADATA: \(uploadMetadata)")
                    
                    let uploadRequest = AWSS3TransferManagerUploadRequest()
                    uploadRequest?.bucket = Constants.Strings.S3BucketUserImages
                    uploadRequest?.metadata = uploadMetadata
                    uploadRequest?.key =  imageID
                    uploadRequest?.body = URL(string: "file:///" + filePath)
                    print("UUI: UPLOAD REQUEST: \(uploadRequest)")
                    
                    let transferManager = AWSS3TransferManager.default()
                    transferManager?.upload(uploadRequest).continue({ (task) -> AnyObject! in
                        if let error = task.error {
                            if error._domain == AWSS3TransferManagerErrorDomain as String
                                && AWSS3TransferManagerErrorType(rawValue: error._code) == AWSS3TransferManagerErrorType.paused {
                                print("Upload paused.")
                            } else {
                                print("Upload failed: [\(error)]")
                                // Delete the user image from temporary memory
                                do {
                                    print("Deleting image: \(imageID)")
                                    try FileManager.default.removeItem(atPath: filePath)
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
                                try FileManager.default.removeItem(atPath: filePath)
                            }
                            catch let error as NSError {
                                print("Ooops! Something went wrong: \(error)")
                            }
                        } else {
                            print("Upload succeeded")
                            // Delete the user image from temporary memory
                            do {
                                print("Deleting image: \(imageID)")
                                try FileManager.default.removeItem(atPath: filePath)
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
    func getUserImage(_ userID: String, imageKey: String) {
        print("AVC - GETTING IMAGE FOR: \(imageKey)")
        
        let downloadingFilePath = NSTemporaryDirectory() + imageKey // + Constants.Settings.frameImageFileType)
        let downloadingFileURL = URL(fileURLWithPath: downloadingFilePath)
        let transferManager = AWSS3TransferManager.default()
        
        // Download the Frame
        let downloadRequest : AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.bucket = Constants.Strings.S3BucketUserImages
        downloadRequest.key =  imageKey
        downloadRequest.downloadingFileURL = downloadingFileURL
        
        transferManager?.download(downloadRequest).continue({ (task) -> AnyObject! in
            if let error = task.error {
                if error._domain == AWSS3TransferManagerErrorDomain as String
                    && AWSS3TransferManagerErrorType(rawValue: error._code) == AWSS3TransferManagerErrorType.paused {
                    print("AVC - DOWNLOAD PAUSED")
                } else {
                    print("AVC - DOWNLOAD FAILED: [\(error)]")
                }
            } else if let exception = task.exception {
                print("AVC - DOWNLOAD FAILED: [\(exception)]")
            } else {
                print("AVC - DOWNLOAD SUCCEEDED")
                DispatchQueue.main.async(execute: { () -> Void in
                    // Assign the image to the Preview Image View
                    if FileManager().fileExists(atPath: downloadingFilePath) {
                        print("IMAGE FILE AVAILABLE")
                        let thumbnailData = try? Data(contentsOf: URL(fileURLWithPath: downloadingFilePath))
                        
                        // Ensure the Thumbnail Data is not null
                        if let tData = thumbnailData {
                            print("GET IMAGE - CHECK 1")
                            
                            self.displayUserImage.image = UIImage(data: tData)
                            self.displayUserImageActivityIndicator.stopAnimating()
                            print("ADDED IMAGE TO DISPLAY USER IMAGE: \(imageKey))")
                            
                            // Save the logged in user data to Core Data for quicker access
                            loopUserObjectCheck: for userObject in Constants.Data.userObjects {
                                if userObject.userID == Constants.Data.currentUser {
                                    
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
                                        entity.setValue(userObject.userID, forKey: "userID")
                                        entity.setValue(userObject.userName, forKey: "userName")
                                        entity.setValue(userObject.userImageKey, forKey: "userImageKey")
                                        entity.setValue(tData, forKey: "userImage")
                                        
                                    } else {
                                        print("CORE DATA - CURRENT USER - MODIFYING DATA")
                                        
                                        // Replace the current user data to ensure that the latest data is used
                                        currentUser[0].userID = userObject.userID
                                        currentUser[0].userName = userObject.userName
                                        currentUser[0].userImageKey = userObject.userImageKey
                                        currentUser[0].userImage = tData
                                    }
                                    
                                    // Save the Entity
                                    do {
                                        try moc.save()
                                    } catch {
                                        fatalError("Failure to save context: \(error)")
                                    }
                                    
                                    break loopUserObjectCheck
                                }
                            }
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
