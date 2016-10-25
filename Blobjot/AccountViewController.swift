//
//  MyBlobsTableViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 7/27/16.
//  Copyright © 2016 tangojlabs. All rights reserved.
//

import AWSLambda
import AWSS3
import FBSDKLoginKit
import GoogleMaps
import UIKit

// Create a protocol with functions declared in other View Controllers implementing this protocol (delegate)
protocol AccountViewControllerDelegate
{
    // When called, the parent View Controller checks for changes to the logged in user
    func logoutUser()
    
    // When called, fire the parent popViewController
    func popViewController()
}

class AccountViewController: UIViewController, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AWSRequestDelegate
{
    // Add a delegate variable which the parent view controller can pass its own delegate instance to and have access to the protocol
    // (and have its own functions called that are listed in the protocol)
    var accountViewDelegate: AccountViewControllerDelegate?
    
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var tabBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    var viewContainer: UIView!
    var statusBarView: UIView!
    
    var displayUserContainer: UIView!
    var displayUserImageContainer: UIView!
    var displayUserImageActivityIndicator: UIActivityIndicatorView!
    var displayUserImage: UIImageView!
    var displayUserLabel: UILabel!
    var displayUserLabelActivityIndicator: UIActivityIndicatorView!
    
    var logoutButton: UIView!
    var logoutButtonLabel: UILabel!
    var locationButton: UIView!
    var locationButtonLabel: UILabel!
    
    var displayUserEditNameView: UIView!
    var editNameCurrentName: UITextView!
    var editNameNewNameLabel: UILabel!
    var editNameNewName: UITextView!
    var editNameSaveButton: UIView!
    var editNameSaveButtonLabel: UILabel!
    var viewScreen: UIView!
    
    var userImageTapGesture: UITapGestureRecognizer!
    var userNameTapGesture: UITapGestureRecognizer!
    var logoutButtonTapGesture: UITapGestureRecognizer!
    var locationButtonTapGesture: UITapGestureRecognizer!
    var editNameSaveButtonTapGesture: UITapGestureRecognizer!
    var viewScreenTapGesture: UITapGestureRecognizer!
    
    var currentUserName: String = ""
    
    var blobUserActivityIndicator: UIActivityIndicatorView!
    var blobsTableViewBackgroundLabel: UILabel!
    var blobsUserTableView: UITableView!
    
//    var userBlobs = [Blob]()
    
    // Create a local property to hold the child VC
    var blobVC: BlobViewController!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Device and Status Bar Settings
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        if let navBarHeight = self.navigationController?.navigationBar.frame.height
        {
            self.navBarHeight = navBarHeight
//            self.statusBarHeight = 0
        }
        else
        {
            self.navBarHeight = 44
        }
        viewFrameY = self.view.frame.minY
        screenSize = UIScreen.main.bounds
        if let tabBarHeight = self.navigationController?.navigationBar.frame.height
        {
            self.tabBarHeight = tabBarHeight
        }
        else
        {
            self.tabBarHeight = 49
        }
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: statusBarHeight + navBarHeight - viewFrameY, width: self.view.frame.width, height: self.view.frame.height - statusBarHeight - navBarHeight - tabBarHeight + viewFrameY))
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        self.view.addSubview(viewContainer)
        
        // Add the display User container to show above the people list and search bar
        displayUserContainer = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: Constants.Dim.accountProfileBoxHeight))
        displayUserContainer.backgroundColor = UIColor.white
        displayUserContainer.layer.shadowOffset = CGSize(width: 0, height: 0.2)
        displayUserContainer.layer.shadowOpacity = 0.2
        displayUserContainer.layer.shadowRadius = 1.0
        
        // Local User Account Box
        displayUserLabel = UILabel(frame: CGRect(x: 0, y: 95, width: viewContainer.frame.width / 2, height: 20))
        displayUserLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        displayUserLabel.textColor = Constants.Colors.colorTextGray
        displayUserLabel.textAlignment = NSTextAlignment.center
        displayUserLabel.isUserInteractionEnabled = true
        
        // Add a loading indicator while downloading the logged in user name
        displayUserLabelActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 90, width: viewContainer.frame.width / 2, height: 30))
        displayUserLabelActivityIndicator.color = UIColor.black
        
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
        var currentUserObjects = UtilityFunctions().cdCurrentUser()
        let currentUserArray = currentUserObjects[0] as! [CurrentUser]
        //        let moc = currentUserObjects[1] as! NSManagedObjectContext
        
        // If the return has content, the current user is saved - use that data
        if currentUserArray.count > 0
        {
            print("CORE DATA - CURRENT USER - GOT USER DATA")
            
            // Apply the current user data in the current user elements
            displayUserLabel.text = currentUserArray[0].userName
            
            if let imageData = currentUserArray[0].userImage
            {
                displayUserImage.image = UIImage(data: imageData)
            }
        }
        
        // Add a custom logout button
        logoutButton = UIView(frame: CGRect(x: (viewContainer.frame.width * 3) / 4 - 50, y: 10, width: 100, height: 45))
        logoutButton.layer.cornerRadius = 5
        logoutButton.layer.borderWidth = 1
        logoutButton.layer.borderColor = Constants.Colors.colorPurple.cgColor
        logoutButton.backgroundColor = Constants.Colors.standardBackground
        
        logoutButtonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: logoutButton.frame.width, height: logoutButton.frame.height))
        logoutButtonLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        logoutButtonLabel.textColor = Constants.Colors.colorPurple
        logoutButtonLabel.textAlignment = NSTextAlignment.center
        logoutButtonLabel.numberOfLines = 2
        logoutButtonLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        logoutButtonLabel.text = "Log Out"
        logoutButton.addSubview(logoutButtonLabel)
        
        // Add a custom location button
        locationButton = UIView(frame: CGRect(x: (viewContainer.frame.width * 3) / 4 - 50, y: displayUserContainer.frame.height - 55, width: 100, height: 45))
        locationButton.layer.cornerRadius = 5
        locationButton.layer.borderWidth = 1
        locationButton.layer.borderColor = Constants.Colors.colorPurple.cgColor
        locationButton.backgroundColor = Constants.Colors.standardBackground
        
        locationButtonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: locationButton.frame.width, height: locationButton.frame.height))
        locationButtonLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        locationButtonLabel.textColor = Constants.Colors.colorPurple
        locationButtonLabel.textAlignment = NSTextAlignment.center
        locationButtonLabel.numberOfLines = 2
        locationButtonLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        locationButton.addSubview(locationButtonLabel)
        
        // Retrieve the LocationManagerSettings in Core Data and assign that setting to the global locationManagerConstant property
        // If Core Data does not have that setting data, assign the default setting "constant" to Core Data
        // Also set the locationManager toggle button color and text based on the global setting
        let locationManagerSettingObjects = UtilityFunctions().cdLocationManagerSetting()
        let locationManagerSettingArray = locationManagerSettingObjects[0] as! [LocationManagerSetting]
        //        let moc = locationManagerSettingObjects[1] as! NSManagedObjectContext
        print("AVC - CD Location Manager Setting Count: \(locationManagerSettingArray.count)")
        
        if locationManagerSettingArray.count > 0
        {
            print("AVC - CD Location Manager Setting: \(locationManagerSettingArray[0].locationManagerSetting)")
            if locationManagerSettingArray[0].locationManagerSetting == "constant"
            {
                Constants.Settings.locationManagerConstant = true
                locationButtonLabel.text = Constants.Strings.stringLMConstant
            }
            else
            {
                Constants.Settings.locationManagerConstant = false
                locationButtonLabel.text = Constants.Strings.stringLMSignificant
            }
        }
        else
        {
            Constants.Settings.locationManagerConstant = true
            locationButtonLabel.text = Constants.Strings.stringLMConstant
            
            // Now save the default to Core Data
            UtilityFunctions().cdLocationManagerSettingSave(true)
        }
        
        if Constants.Data.currentUser != ""
        {
            displayUserContainer.addSubview(displayUserLabel)
            displayUserContainer.addSubview(displayUserLabelActivityIndicator)
            displayUserLabelActivityIndicator.startAnimating()
            displayUserContainer.addSubview(displayUserImageContainer)
            displayUserImageContainer.addSubview(displayUserImageActivityIndicator)
            displayUserImageActivityIndicator.startAnimating()
            displayUserContainer.addSubview(logoutButton)
            displayUserContainer.addSubview(locationButton)
        }
        
        // Add a loading indicator while downloading the logged in user image
        blobUserActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: Constants.Dim.accountProfileBoxHeight, width: viewContainer.frame.width, height: Constants.Dim.accountTableViewCellHeight))
        blobUserActivityIndicator.color = UIColor.black
        viewContainer.addSubview(blobUserActivityIndicator)
        blobUserActivityIndicator.startAnimating()
        
        blobsTableViewBackgroundLabel = UILabel(frame: CGRect(x: 10, y: 10 + Constants.Dim.accountProfileBoxHeight, width: viewContainer.frame.width - 20, height: Constants.Dim.accountTableViewCellHeight - 20))
        blobsTableViewBackgroundLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 20)
        blobsTableViewBackgroundLabel.numberOfLines = 0
        blobsTableViewBackgroundLabel.lineBreakMode = .byWordWrapping
        blobsTableViewBackgroundLabel.textColor = Constants.Colors.colorTextStandard
        blobsTableViewBackgroundLabel.textAlignment = .center
        blobsTableViewBackgroundLabel.text = ""
        viewContainer.addSubview(blobsTableViewBackgroundLabel)
        
        blobsUserTableView = UITableView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        blobsUserTableView.dataSource = self
        blobsUserTableView.delegate = self
        blobsUserTableView.register(AccountTableViewCell.self, forCellReuseIdentifier: Constants.Strings.accountTableViewCellReuseIdentifier)
        blobsUserTableView.separatorStyle = .none
        blobsUserTableView.backgroundColor = UIColor.clear
        blobsUserTableView.alwaysBounceVertical = true
        blobsUserTableView.showsVerticalScrollIndicator = false
        blobsUserTableView.contentInset = UIEdgeInsets(top: 5 + Constants.Dim.accountProfileBoxHeight, left: 0, bottom: 0, right: 0)
        viewContainer.addSubview(blobsUserTableView)
        
//        self.tableView.registerClass(ListTableViewCell.self, forCellReuseIdentifier: Constants.Strings.listTableViewCellReuseIdentifier)
//        self.tableView.contentInset = UIEdgeInsets(top: statusBarHeight, left: 0, bottom: 0, right: 0)
        
        // Now add the profile box so that it is on top of all other sub-views
        viewContainer.addSubview(displayUserContainer)
        
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
        
        locationButtonTapGesture = UITapGestureRecognizer(target: self, action: #selector(AccountViewController.locationButtonTapGesture(_:)))
        locationButtonTapGesture.numberOfTapsRequired = 1  // add single tap
        locationButton.addGestureRecognizer(locationButtonTapGesture)
        
        editNameSaveButtonTapGesture = UITapGestureRecognizer(target: self, action: #selector(AccountViewController.editNameSaveButtonTapGesture(_:)))
        editNameSaveButtonTapGesture.numberOfTapsRequired = 1  // add single tap
        editNameSaveButton.addGestureRecognizer(editNameSaveButtonTapGesture)
        
        viewScreenTapGesture = UITapGestureRecognizer(target: self, action: #selector(AccountViewController.viewScreenTapGesture(_:)))
        viewScreenTapGesture.numberOfTapsRequired = 1  // add single tap
        viewScreen.addGestureRecognizer(viewScreenTapGesture)
        
        // Add the Status Bar, Top Bar and Search Bar
        statusBarView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 20))
        statusBarView.backgroundColor = Constants.Colors.colorStatusBar
        self.view.addSubview(statusBarView)
        
        // Request the Blobs that the user has posted
        blobUserActivityIndicator.startAnimating()
        AWSPrepRequest(requestToCall: AWSGetUserBlobs(), delegate: self as AWSRequestDelegate).prepRequest()
        
        // Refresh the Current User Elements
        self.refreshCurrentUserElements()
        
        // Go ahead and request the user data from AWS again in case the data has been updated
        AWSPrepRequest(requestToCall: AWSGetSingleUserData(userID: Constants.Data.currentUser, forPreviewBox: false), delegate: self as AWSRequestDelegate).prepRequest()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: GESTURE RECOGNIZERS
    
    // Reveal the popup screen to edit the userName
    func viewScreenTapGesture(_ sender: UITapGestureRecognizer)
    {
        hideScreenAndEditNameBox()
    }
    
    func hideScreenAndEditNameBox()
    {
        // Remove the gray screen
        self.viewScreen.removeFromSuperview()
        
        // Animate the user name edit popup out of view
        UIView.animate(withDuration: 0.2, animations:
            {
                self.displayUserEditNameView.frame = CGRect(x: 50, y: self.viewContainer.frame.height, width: self.viewContainer.frame.width - 100, height: self.viewContainer.frame.width - 50)
            }, completion:
            { (finished: Bool) -> Void in
                self.displayUserEditNameView.removeFromSuperview()
        })
    }
    
    // Reveal the popup screen to edit the userName
    func userNameTapGesture(_ sender: UITapGestureRecognizer)
    {
        print("EDIT USER NAME: \(currentUserName)")
        
        // Show the gray screen to highlight the name editor popup
        self.viewContainer.addSubview(viewScreen)
        self.viewContainer.addSubview(displayUserEditNameView)
        
        DispatchQueue.main.async(execute:
            {
                self.editNameCurrentName.text = "Current User Name:\n " + self.currentUserName
        })
        
        // Add an animation to bring the edit user name screen into view
        UIView.animate(withDuration: 0.2, animations:
            {
                self.displayUserEditNameView.frame = CGRect(x: 50, y: 50, width: self.viewContainer.frame.width - 100, height: 200)
            }, completion: nil)
    }
    
    // Log out the user from the app and facebook
    func logoutButtonTapGesture(_ sender: UITapGestureRecognizer)
    {
        print("TRYING TO LOG OUT THE USER")
        
        // Log out the user from Facebook
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        
        // Log out the user from the app
        Constants.Data.currentUser = ""
        Constants.credentialsProvider.clearCredentials()
        
        // Clear the data from the app
        Constants.Data.mapBlobs = [Blob]()
        Constants.Data.userBlobs = [Blob]()
        Constants.Data.locationBlobs = [Blob]()
        Constants.Data.blobThumbnailObjects = [BlobThumbnailObject]()
        Constants.Data.userObjects = [User]()
        
        for circle in Constants.Data.mapCircles
        {
            circle.map = nil
        }
        Constants.Data.mapCircles = [GMSCircle]()
        
        // Call the parent VC to remove the current VC from the stack
        if let parentVC = self.accountViewDelegate
        {
            parentVC.popViewController()
            parentVC.logoutUser()
        }
    }
    
    // Toggle the location manager type
    func locationButtonTapGesture(_ sender: UITapGestureRecognizer)
    {
        print("TOGGLE THE LOCATION MANAGER SETTINGS")
        
        // Toggle the location manager type
        if Constants.Settings.locationManagerConstant
        {
            // Change the locationManagerAlways toggle indicator
            Constants.Settings.locationManagerConstant = false
            
            // Change the button color and text
            locationButtonLabel.text = Constants.Strings.stringLMSignificant
            
            // Save the locationManagerSetting in Core Data
            UtilityFunctions().cdLocationManagerSettingSave(false)
        }
        else
        {
            // Change the locationManagerAlways toggle indicator
            Constants.Settings.locationManagerConstant = true
            
            // Change the button color and text
            locationButtonLabel.text = Constants.Strings.stringLMConstant
            
            // Save the locationManagerSetting in Core Data
            UtilityFunctions().cdLocationManagerSettingSave(true)
        }
    }
    
    // Save the newly typed user name
    func editNameSaveButtonTapGesture(_ sender: UITapGestureRecognizer)
    {
        // Save the userName to AWS and show in the display user label
        if let newUserName = self.editNameNewName.text
        {
            // Ensure that the new username is not blank
            if newUserName != ""
            {
                // Close the keyboard and hide the screen and edit name box
                self.view.endEditing(true)
                self.hideScreenAndEditNameBox()
                
                // Show the new name in the display user label
                self.displayUserLabel.text = newUserName
                
                // Upload the new username to AWS
                AWSPrepRequest(requestToCall: AWSEditUserName(newUserName: newUserName), delegate: self as AWSRequestDelegate).prepRequest()
                
                // Edit the logged in user's userName in the global list
                userLoop: for userObject in Constants.Data.userObjects
                {
                    if userObject.userID == Constants.Data.currentUser
                    {
                        userObject.userName = newUserName
                        break userLoop
                    }
                }
            }
        }
    }
    
    // Update the User Image using a media picker
    func imageTapGesture(_ sender: UITapGestureRecognizer)
    {
        // Show the gray screen to indicate that the picker is loading
        viewContainer.addSubview(viewScreen)
        
        // Load the image picker - allow only photos
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    // ImagePicker Delegate Methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        // Remove the gray screen
        self.viewScreen.removeFromSuperview()
        
        // Process the picked image
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            // Assign the new image to the local userImage view
            displayUserImage.image = pickedImage
            
            // Update the global userObject with the new image
            loopUserObjectCheck: for userObject in Constants.Data.userObjects
            {
                if userObject.userID == Constants.Data.currentUser
                {
                    userObject.userImage = pickedImage
                    
                    break loopUserObjectCheck
                }
            }
            
            // Upload the new user image to AWS and update the userImageKey
            AWSPrepRequest(requestToCall: AWSEditUserImage(newUserImage: pickedImage), delegate: self as AWSRequestDelegate).prepRequest()
        }
        self.dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        // Remove the gray screen
        self.viewScreen.removeFromSuperview()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // #warning Incomplete implementation, return the number of rows
        return Constants.Data.userBlobs.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return Constants.Dim.blobsActiveTableViewCellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.accountTableViewCellReuseIdentifier, for: indexPath) as! AccountTableViewCell
        
        // Clear the cell contents (so reused cells are not showing incorrect data)
        cell.cellDate.text = ""
        cell.cellTime.text = ""
        cell.cellBlobTypeIndicator.backgroundColor = UIColor.clear
        cell.cellThumbnail.image = nil
//        cell.cellText.text = ""
        
        // Add a clear background for the selectedBackgroundView so that the row is not highlighted when selected
        let sbv = UIView(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height))
        sbv.backgroundColor = UIColor.clear
        cell.selectedBackgroundView = sbv
        
        // Retrieve the Blob associated with this cell
        let cellBlob = Constants.Data.userBlobs[(indexPath as NSIndexPath).row]
        
        // Convert the Blob timestamp to readable format and assign
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, MMM d"
        let stringDate: String = dateFormatter.string(from: cellBlob.blobDatetime as Date)
        cell.cellDate.text = stringDate
        
        // Convert the Blob timestamp to readable format and assign
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let stringTime: String = timeFormatter.string(from: cellBlob.blobDatetime as Date)
        cell.cellTime.text = stringTime
        
        // Interpret the Blob Type Indicator color from the conversion function
        cell.cellBlobTypeIndicator.backgroundColor = Constants().blobColorOpaque(cellBlob.blobType)
        
        // If the Blob has a thumbnail, assign it to the Blob image view, or assign the Blob text if no thumbnail exists (and call for the image if the ID exists)
        if let thumbnail = cellBlob.blobThumbnail
        {
            cell.cellThumbnail.image = thumbnail
        }
        else
        {
            cell.cellText.text = cellBlob.blobText
            
            // Request the thumbnail image if the thumbnailID exists
            if cellBlob.blobThumbnailID != nil
            {
                AWSPrepRequest(requestToCall: AWSGetThumbnailImage(blob: cellBlob), delegate: self as AWSRequestDelegate).prepRequest()
            }
        }
        return cell
    }
    
    
    // For the slide action to delete the Blob
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        // Retrieve the Blob associated with this cell
        let cellBlob = Constants.Data.userBlobs[(indexPath as NSIndexPath).row]
        
        // Create a dummy action to add to the initial action array
        let actionReturn = UITableViewRowAction()
        var actionReturnArray = [actionReturn]
        
        // If the row's Blob is a Permanent Blob, allow deletion.  Otherwise, show the error message and DO NOT allow deletion
        if cellBlob.blobType == Constants.BlobTypes.permanent
        {
            let delete = UITableViewRowAction(style: .normal, title: "Delete\nBlob") { action, index in
                print("delete button tapped")
                
                // Remove the Blob from the userBlobs array (so it disappears from the Table View)
                Constants.Data.userBlobs.remove(at: (indexPath as NSIndexPath).row)
                
                // Refresh the Table View to no longer show that row
                self.blobsUserTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
                
                // Record the Blob deletion in AWS so that the Blob no longer is downloaded for anyone
                AWSPrepRequest(requestToCall: AWSDeleteBlob(blobID: cellBlob.blobID, userID: Constants.Data.currentUser), delegate: self as AWSRequestDelegate).prepRequest()
                
                // Remove the Circle for this Blob from the map Circles so that it no longer shows on the Map View
                loopMapCirclesCheck: for (cIndex, circle) in Constants.Data.mapCircles.enumerated()
                {
                    if circle.title == cellBlob.blobID
                    {
                        print("DELETING CIRCLE: \(circle.title)")
                        circle.map = nil
                        Constants.Data.mapCircles.remove(at: cIndex)
                        
                        break loopMapCirclesCheck
                    }
                }
            }
            delete.backgroundColor = UIColor.red
            actionReturnArray = [delete]
        }
        else
        {
            // Show the error message
            let alertController = UtilityFunctions().createAlertOkView("Uh oh!", message: "Sorry, you can only delete permanent blobs.")
            self.present(alertController, animated: true, completion: nil)
        }
        return actionReturnArray
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print("DID SELECT ROW #\((indexPath as NSIndexPath).item)!")
        
        // Prevent the row from being highlighted
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Load the Blob View Controller with the selected Blob
        print("USER BLOB COUNT: \(Constants.Data.userBlobs.count)")
        if Constants.Data.userBlobs.count >= (indexPath as NSIndexPath).row
        {
            self.loadBlobViewWithBlob(Constants.Data.userBlobs[(indexPath as NSIndexPath).row])
        }
        
        // Reference the cell and start the loading indicator
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.accountTableViewCellReuseIdentifier, for: indexPath) as! AccountTableViewCell
        print("SELECTED CELL \((indexPath as NSIndexPath).row): \(cell)")
        cell.cellSelectedActivityIndicator.startAnimating()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
        print("DID DESELECT ROW: \((indexPath as NSIndexPath).row)")
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath)
    {
        print("DID HIGHLIGHT ROW: \((indexPath as NSIndexPath).row)")
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath)
    {
        print("DID UNHIGHLIGHT ROW: \((indexPath as NSIndexPath).row)")
    }
    
    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
//        if editingStyle == .Delete {
//            // Delete the row from the data source
//            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
//        } else if editingStyle == .Insert {
//            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//        }
    }
    
    
    
    
    // MARK: CUSTOM FUNCTION
    
    // Dismiss the latest View Controller presented from this VC
    // This version is used when the top VC is popped from a Nav Bar button
    func popViewController(_ sender: UIBarButtonItem)
    {
        print("pop Back to Table View")
        self.dismiss(animated: true, completion: nil)
    }
    
    func loadBlobViewWithBlob(_ blob: Blob)
    {
        print("LOADING USER LIST BLOB")
        print(blob.blobExtraRequested)
        print(blob.blobText)
        print(blob.blobThumbnailID)
        if blob.blobText != nil || blob.blobThumbnailID != nil
        {
            // Create a back button and title for the Nav Bar
            let backButtonItem = UIBarButtonItem(title: "ACCOUNT \u{2193}",
                                                 style: UIBarButtonItemStyle.plain,
                                                 target: self,
                                                 action: #selector(AccountViewController.popViewController(_:)))
            backButtonItem.tintColor = Constants.Colors.colorTextNavBar
            
            let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
            let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
            
            // Find the correct User Object in the global list and assign the userName to the nav bar title
            loopUserObjectCheck: for userObject in Constants.Data.userObjects
            {
                if userObject.userID == blob.blobUserID
                {
                    ncTitleText.text = userObject.userName
                    break loopUserObjectCheck
                }
            }
            ncTitleText.textColor = Constants.Colors.colorTextNavBar
            ncTitleText.textAlignment = .center
            ncTitle.addSubview(ncTitleText)
            
            // Instantiate the BlobViewController and pass the Preview Blob to the VC
            blobVC = BlobViewController()
            blobVC.blob = blob
            blobVC.userBlob = true
            
            // Instantiate the Nav Controller and attach the Nav Bar items to the view controller settings
            let navController = UINavigationController(rootViewController: blobVC)
            blobVC.navigationItem.setLeftBarButton(backButtonItem, animated: true)
            blobVC.navigationItem.titleView = ncTitle
            
            // Change the Nav Bar color and present the view
            navController.navigationBar.barTintColor = Constants.Colors.colorStatusBar
            self.present(navController, animated: true, completion: nil)
        }
    }
    
    // The Child View Controller will call this function when the logged in user has been added to the global user list
    func refreshCurrentUserElements()
    {
        // Check to see if the current user data is already in Core Data
        // Try to retrieve the current user data from Core Data
        var currentUserObjects = UtilityFunctions().cdCurrentUser()
        let currentUserArray = currentUserObjects[0] as! [CurrentUser]
        
        print("CHECKING CORE DATA - CURRENT USER COUNT: \(currentUserArray.count)")
        
        // If the return has content, use it to populate the user elements
        if currentUserArray.count > 0
        {
            print("CHECKING CORE DATA - USE PREVIOUS IMAGE DATA")
            
            if let userName = currentUserArray[0].userName
            {
                currentUserName  = userName
                displayUserLabel.text = userName
                displayUserLabelActivityIndicator.stopAnimating()
            }
            
            // Else use the saved current user data until the data is updated
            if let imageData = currentUserArray[0].userImage
            {
                print("CHECKING CORE DATA - PREVIOUS IMAGE DATA EXISTS")
                self.displayUserImage.image = UIImage(data: imageData as Data)
                self.displayUserImageActivityIndicator.stopAnimating()
            }
        }
        
        // Find the logged in User Object in the global User list and use the data to fill out the user display views
        userLoop: for userObject in Constants.Data.userObjects
        {
            print("GLOBAL LIST USER CHECK: \(userObject.userName)")
            
            if userObject.userID == Constants.Data.currentUser
            {
                print("IN PARENT - GOT CURRENT USER: \(userObject.userName)")
                
                // Show the logged in user's username in the display user label
                currentUserName  = userObject.userName
                displayUserLabel.text = userObject.userName
                displayUserLabelActivityIndicator.stopAnimating()
                
                // Refresh the user image if it exists
                if let userImage = userObject.userImage
                {
                    self.displayUserImage.image = userImage
                    self.displayUserImageActivityIndicator.stopAnimating()
                    print("ADDED IMAGE TO DISPLAY USER IMAGE: \(userObject.userImageKey))")
                    
                    // Store the new image in Core Data for immediate access in next VC loading
                    UtilityFunctions().cdCurrentUserSave(userObject)
                }
                
                break userLoop
            }
        }
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("AVC - SHOW LOGIN SCREEN")
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
        DispatchQueue.main.async(execute:
            {
                // Process the return data based on the method used
                switch objectType
                {
                case _ as AWSGetUserImage:
                    if success
                    {
                        // Refresh the user elements
                        self.refreshCurrentUserElements()
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case _ as AWSGetSingleUserData:
                    if success
                    {
                        // Refresh the user elements
                        self.refreshCurrentUserElements()
                        
                        // Refresh child VCs
                        if self.blobVC != nil
                        {
                            self.blobVC.refreshDataManually()
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
                case _ as AWSDeleteBlob:
                    if !success
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case let awsGetUserBlobs as AWSGetUserBlobs:
                    if success
                    {
                        if let newUserBlobs = awsGetUserBlobs.newUserBlobs {
                            if newUserBlobs.count <= 0
                            {
                                // The User has not created any Blobs, so stop the loading animation and show the message
                                self.blobUserActivityIndicator.stopAnimating()
                                self.blobsTableViewBackgroundLabel.text = "You have not yet created a Blob.  Tap the add button on the Map Screen to create a new Blob!"
                            }
                            else
                            {
                                // Loop through each AnyObject (Blob) in the array
                                for newBlob in newUserBlobs
                                {
                                    print("NEW BLOB: \(newBlob)")
                                    
                                    // Convert the AnyObject to JSON with keys and AnyObject values
                                    // Then convert the AnyObject values to Strings or Numbers depending on their key
                                    if let checkBlob = newBlob as? [String: AnyObject]
                                    {
                                        // Finish converting the JSON AnyObjects and assign the data to a new Blob Object
                                        print("ASSIGNING DATA")
                                        let addBlob = Blob()
                                        addBlob.blobID = checkBlob["blobID"] as! String
                                        addBlob.blobDatetime = Date(timeIntervalSince1970: checkBlob["blobTimestamp"] as! Double)
                                        addBlob.blobLat = checkBlob["blobLat"] as! Double
                                        addBlob.blobLong = checkBlob["blobLong"] as! Double
                                        addBlob.blobRadius = checkBlob["blobRadius"] as! Double
                                        addBlob.blobType = Constants().blobTypes(checkBlob["blobType"] as! Int)
                                        addBlob.blobUserID = checkBlob["blobUserID"] as! String
                                        addBlob.blobText = checkBlob["blobText"] as? String
                                        addBlob.blobThumbnailID = checkBlob["blobThumbnailID"] as? String
                                        addBlob.blobMediaType = checkBlob["blobMediaType"] as? Int
                                        addBlob.blobMediaID = checkBlob["blobMediaID"] as? String
                                        
                                        // Append the new Blob Object to the local User Blobs Array
                                        Constants.Data.userBlobs.append(addBlob)
                                        print("APPENDED BLOB: \(addBlob.blobID)")
                                    }
                                }
                                // Sort the User Blobs from newest to oldest
                                Constants.Data.userBlobs.sort(by: {$0.blobDatetime.timeIntervalSince1970 > $1.blobDatetime.timeIntervalSince1970})
                                
                                // Refresh the Table View
                                self.blobsUserTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
                            }
                        }
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case let awsGetThumbnailImage as AWSGetThumbnailImage:
                    if success
                    {
                        // Find the correct User Object in the global list and assign the newly downloaded Image
                        loopUserObjectCheck: for blobObject in Constants.Data.userBlobs {
                            if blobObject.blobID == awsGetThumbnailImage.blob.blobID {
                                blobObject.blobThumbnail = awsGetThumbnailImage.blob.blobThumbnail
                                
                                break loopUserObjectCheck
                            }
                        }
                        
                        print("ADDED IMAGE: \(awsGetThumbnailImage.blob.blobThumbnailID))")
                        
                        // Reload the Table View
                        print("GET IMAGE - RELOAD TABLE VIEW")
                        self.blobsUserTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
                        
                        // Refresh child VCs
                        if self.blobVC != nil
                        {
                            self.blobVC.refreshDataManually()
                        }
                    }
                    else
                    {
                        print("AVC-awsGetThumbnailImage: ERROR")
//                        // Show the error message
//                        let alertController = UtilityFunctions().createAlertOkView("AWSGetThumbnailImage Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
//                        self.present(alertController, animated: true, completion: nil)
                    }
                default:
                    print("AVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    // Show the error message
                    let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    self.present(alertController, animated: true, completion: nil)
                }
        })
    }
    
}
