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

class AccountViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AWSRequestDelegate, HoleViewDelegate
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
    
    var userImageTapGesture: UITapGestureRecognizer!
    var userNameTapGesture: UITapGestureRecognizer!
    var logoutButtonTapGesture: UITapGestureRecognizer!
    var locationButtonTapGesture: UITapGestureRecognizer!
    
//    var blobUserActivityIndicator: UIActivityIndicatorView!
    var blobsTableViewBackgroundLabel: UILabel!
    var blobsUserTableView: UITableView!
    
    var usernameAvailable: Bool = false
    var usernameCheckTimestamp: TimeInterval = Date().timeIntervalSince1970
    
    // MUST USE a local array, in case the global array is updated in the background
    var userBlobs = [Blob]()
    
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
        let currentUserArray = CoreDataFunctions().currentUserRetrieve()
        
        // If the return has content, the current user is saved - use that data
        if currentUserArray.count > 0
        {
            print("CORE DATA - CURRENT USER - GOT USER DATA")
            
            // Apply the current user data in the current user elements
            displayUserLabel.text = currentUserArray[0].userName
            
            if let imageData = currentUserArray[0].userImage
            {
                displayUserImage.image = UIImage(data: imageData as Data)
            }
        }
        
        // Add a custom logout button
        logoutButton = UIView(frame: CGRect(x: (viewContainer.frame.width * 3) / 4 - 65, y: 10, width: 130, height: 45))
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
        locationButton = UIView(frame: CGRect(x: (viewContainer.frame.width * 3) / 4 - 65, y: displayUserContainer.frame.height - 55, width: 130, height: 45))
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
        let locationManagerSettingArray = CoreDataFunctions().locationManagerSettingRetrieve()
        print("AVC - CD Location Manager Setting Count: \(locationManagerSettingArray.count)")
        
        if locationManagerSettingArray.count == 0
        {
            // If the array is empty, no previous setting was saved - set and save the default
            
            Constants.Settings.locationManagerSetting = Constants.LocationManagerSettingType.significant
            locationButtonLabel.text = Constants.Strings.stringLMSignificant
            
            // Now save the default to Core Data
            CoreDataFunctions().locationManagerSettingSave(Constants.LocationManagerSettingType.significant)
        }
        else
        {
            print("AVC - CD Location Manager Setting: \(locationManagerSettingArray[0].locationManagerSetting)")
            if locationManagerSettingArray[0].locationManagerSetting == Constants.LocationManagerSettingType.always.rawValue
            {
                Constants.Settings.locationManagerSetting = Constants.LocationManagerSettingType.always
                locationButtonLabel.text = Constants.Strings.stringLMAlways
            }
            else if locationManagerSettingArray[0].locationManagerSetting == Constants.LocationManagerSettingType.off.rawValue
            {
                Constants.Settings.locationManagerSetting = Constants.LocationManagerSettingType.off
                locationButtonLabel.text = Constants.Strings.stringLMOff
            }
            else
            {
                Constants.Settings.locationManagerSetting = Constants.LocationManagerSettingType.significant
                locationButtonLabel.text = Constants.Strings.stringLMSignificant
            }
        }
        
        if Constants.Data.currentUser.userID != nil
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
        
//        // Add a loading indicator while downloading the logged in user image
//        blobUserActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: Constants.Dim.accountProfileBoxHeight, width: viewContainer.frame.width, height: Constants.Dim.accountTableViewCellHeight))
//        blobUserActivityIndicator.color = UIColor.black
//        viewContainer.addSubview(blobUserActivityIndicator)
//        blobUserActivityIndicator.startAnimating()
        
        blobsTableViewBackgroundLabel = UILabel(frame: CGRect(x: 10, y: 10 + Constants.Dim.accountProfileBoxHeight, width: viewContainer.frame.width - 20, height: Constants.Dim.accountTableViewCellHeight - 20))
        blobsTableViewBackgroundLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 20)
        blobsTableViewBackgroundLabel.numberOfLines = 0
        blobsTableViewBackgroundLabel.lineBreakMode = .byWordWrapping
        blobsTableViewBackgroundLabel.textColor = Constants.Colors.colorTextStandard
        blobsTableViewBackgroundLabel.textAlignment = .center
        blobsTableViewBackgroundLabel.text = "You haven't created any Blobs yet.  Go to the Map View to add new Blobs!"
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
        
        logoutButtonTapGesture = UITapGestureRecognizer(target: self, action: #selector(AccountViewController.logoutButtonTapGesture(_:)))
        logoutButtonTapGesture.numberOfTapsRequired = 1  // add single tap
        logoutButton.addGestureRecognizer(logoutButtonTapGesture)
        
        locationButtonTapGesture = UITapGestureRecognizer(target: self, action: #selector(AccountViewController.locationButtonTapGesture(_:)))
        locationButtonTapGesture.numberOfTapsRequired = 1  // add single tap
        locationButton.addGestureRecognizer(locationButtonTapGesture)
        
        // Add the Status Bar, Top Bar and Search Bar
        statusBarView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 20))
        statusBarView.backgroundColor = Constants.Colors.colorStatusBar
        self.view.addSubview(statusBarView)
        
        // Request the Blobs that the user has posted
//        blobUserActivityIndicator.startAnimating()
        AWSPrepRequest(requestToCall: AWSGetUserBlobs(), delegate: self as AWSRequestDelegate).prepRequest()
        
        // Refresh the Current User Elements
        self.refreshCurrentUserElements()
        
        // Reset the userBlobs array and try to load the userBlobs from Core Data
        userBlobs = [Blob]()
        let savedBlobs = CoreDataFunctions().blobRetrieve()
        print("AVC - GOT SAVED BLOBS: COUNT: \(savedBlobs.count)")
        for sBlob in savedBlobs
        {
            if sBlob.blobUserID == Constants.Data.currentUser.userID && sBlob.blobType == Constants.BlobTypes.permanent
            {
                print("AVC - SAVED BLOB: \(sBlob.blobID)")
                userBlobs.append(sBlob)
            }
        }
        
        // Sort the User Blobs from newest to oldest
        userBlobs.sort(by: {$0.blobDatetime.timeIntervalSince1970 > $1.blobDatetime.timeIntervalSince1970})
        
        // Go ahead and request the user data from AWS again in case the data has been updated
        if let currentUserID = Constants.Data.currentUser.userID
        {
            AWSPrepRequest(requestToCall: AWSGetSingleUserData(userID: currentUserID, forPreviewBox: false), delegate: self as AWSRequestDelegate).prepRequest()
        }
        
        // Recall the Tutorial Views data in Core Data.  If it is empty for the current ViewController's tutorial, it has not been seen by the curren user.
        let tutorialViews = CoreDataFunctions().tutorialViewRetrieve()
        print("AVC: TUTORIAL VIEWS ACCOUNTVIEW: \(tutorialViews.tutorialAccountViewDatetime)")
        if tutorialViews.tutorialAccountViewDatetime == nil
//        if 2 == 2
        {
            let holeView = HoleView(holeViewPosition: 1, frame: viewContainer.bounds, circleOffsetX: 10, circleOffsetY: 200, circleRadius: 100, textOffsetX: (viewContainer.bounds.width / 2) - 50, textOffsetY: 50, textWidth: 200, textFontSize: 24, text: "This list shows the permanent Blobs you have created.  No temporary Blobs are accessible for management.")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: HOLE VIEW DELEGATE
    func holeViewRemoved(removingViewAtPosition: Int)
    {
        switch removingViewAtPosition
        {
            
        default:
            print("AVC - FINISHED ALL HOLE VIEWS")
            
            // Record the Tutorial View in Core Data
            let moc = DataController().managedObjectContext
            let tutorialView = NSEntityDescription.insertNewObject(forEntityName: "TutorialViews", into: moc) as! TutorialViews
            tutorialView.setValue(NSDate(), forKey: "tutorialAccountViewDatetime")
            CoreDataFunctions().tutorialViewSave(tutorialViews: tutorialView)
        }
    }
    
    
    // MARK: GESTURE RECOGNIZERS
    
//    // Reveal the popup screen to edit the userName
//    func viewScreenTapGesture(_ sender: UITapGestureRecognizer)
//    {
//        hideScreenAndEditNameBox()
//        
//        // Save an action in Core Data
//        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
//    }
//    
//    func hideScreenAndEditNameBox()
//    {
//        // Remove the gray screen
//        self.viewScreen.removeFromSuperview()
//        
//        // Animate the user name edit popup out of view
//        UIView.animate(withDuration: 0.2, animations:
//            {
//                self.displayUserEditNameView.frame = CGRect(x: 50, y: self.viewContainer.frame.height, width: self.viewContainer.frame.width - 100, height: self.viewContainer.frame.width - 50)
//            }, completion:
//            { (finished: Bool) -> Void in
//                self.displayUserEditNameView.removeFromSuperview()
//        })
//        
//        // Save an action in Core Data
//        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
//    }
    
    
    // Log out the user from the app and facebook
    func logoutButtonTapGesture(_ sender: UITapGestureRecognizer)
    {
        print("TRYING TO LOG OUT THE USER")
        
        // Log out the user from Facebook
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        
        // Log out the user from the app
        Constants.Data.currentUser = User()
        Constants.credentialsProvider.clearCredentials()
        
        // Clear the data from the app
        Constants.Data.mapBlobs = [Blob]()
        Constants.Data.taggedBlobs = [Blob]()
        Constants.Data.userBlobs = [Blob]()
        Constants.Data.locationBlobs = [Blob]()
        Constants.Data.blobThumbnailObjects = [BlobThumbnailObject]()
        Constants.Data.userObjects = [User]()
        
        // Remove the userBlobs from the local array and refresh the tableView
        self.userBlobs = [Blob]()
        self.blobsUserTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
        
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
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    // Toggle the location manager type
    func locationButtonTapGesture(_ sender: UITapGestureRecognizer)
    {
        print("TOGGLE THE LOCATION MANAGER SETTINGS")
        
        // Toggle the location manager type
        if Constants.Settings.locationManagerSetting == Constants.LocationManagerSettingType.always
        {
            // Change the locationManagerAlways toggle indicator
            Constants.Settings.locationManagerSetting = Constants.LocationManagerSettingType.significant
            
            // Change the button color and text
            locationButtonLabel.text = Constants.Strings.stringLMSignificant
            
            // Save the locationManagerSetting in Core Data
            CoreDataFunctions().locationManagerSettingSave(Constants.LocationManagerSettingType.significant)
        }
        else if Constants.Settings.locationManagerSetting == Constants.LocationManagerSettingType.off
        {
            // Change the locationManagerAlways toggle indicator
            Constants.Settings.locationManagerSetting = Constants.LocationManagerSettingType.always
            
            // Change the button color and text
            locationButtonLabel.text = Constants.Strings.stringLMAlways
            
            // Save the locationManagerSetting in Core Data
            CoreDataFunctions().locationManagerSettingSave(Constants.LocationManagerSettingType.always)
        }
        else
        {
            // Change the locationManagerAlways toggle indicator
            Constants.Settings.locationManagerSetting = Constants.LocationManagerSettingType.off
            
            // Change the button color and text
            locationButtonLabel.text = Constants.Strings.stringLMOff
            
            // Save the locationManagerSetting in Core Data
            CoreDataFunctions().locationManagerSettingSave(Constants.LocationManagerSettingType.off)
        }
        
        // Implement the changed settings immediately
        UtilityFunctions().toggleLocationManagerSettings()
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
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
        return self.userBlobs.count
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
        let cellBlob = self.userBlobs[(indexPath as NSIndexPath).row]
        
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
        cell.cellBlobTypeIndicator.backgroundColor = Constants().blobColorOpaque(cellBlob.blobType, mainMap: false)
        
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
        let cellBlob = self.userBlobs[(indexPath as NSIndexPath).row]
        
        // Create a dummy action to add to the initial action array
        let actionReturn = UITableViewRowAction()
        var actionReturnArray = [actionReturn]
        
        // If the row's Blob is a Permanent Blob, allow deletion.  Otherwise, show the error message and DO NOT allow deletion
        if cellBlob.blobType == Constants.BlobTypes.permanent
        {
            let delete = UITableViewRowAction(style: .normal, title: "Delete\nBlob") { action, index in
                print("delete button tapped")
                
                // Remove the Blob from the userBlobs array (so it disappears from the Table View)
                self.userBlobs.remove(at: (indexPath as NSIndexPath).row)
                
                // Refresh the Table View to no longer show that row
                self.blobsUserTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
                
                // Remove the Blob from the global array as well
                for (uIndex, uBlob) in Constants.Data.userBlobs.enumerated()
                {
                    if uBlob.blobID == cellBlob.blobID
                    {
                        // Remove the Blob from the global userBlobs array
                        Constants.Data.userBlobs.remove(at: uIndex)
                    }
                }
                
                if let currentUserID = Constants.Data.currentUser.userID
                {
                    // Record the Blob deletion in AWS so that the Blob no longer is downloaded for anyone
                    AWSPrepRequest(requestToCall: AWSDeleteBlob(blobID: cellBlob.blobID, userID: currentUserID), delegate: self as AWSRequestDelegate).prepRequest()
                }
                
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
            delete.backgroundColor = Constants.Colors.blobRedOpaque
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
        print("USER BLOB COUNT: \(self.userBlobs.count)")
        if self.userBlobs.count >= (indexPath as NSIndexPath).row
        {
            self.loadBlobViewWithBlob(self.userBlobs[(indexPath as NSIndexPath).row])
        }
        
        // Reference the cell and start the loading indicator
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.accountTableViewCellReuseIdentifier, for: indexPath) as! AccountTableViewCell
        print("SELECTED CELL \((indexPath as NSIndexPath).row): \(cell)")
        cell.cellSelectedActivityIndicator.startAnimating()
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
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
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    // The Child View Controller will call this function when the logged in user has been added to the global user list
    func refreshCurrentUserElements()
    {
        print("AVC-RCUE - REFRESH CURRENT USER DATA")
        
        // The Current User Data has already been loaded into the global current User object, and possibly updated 
        // from a fresh download of user data when this viewController was loaded
        
        // Show the logged in user's username in the display user label
        if let username = Constants.Data.currentUser.userName
        {
            Constants.Data.currentUser.userName  = username
            displayUserLabel.text = username
            displayUserLabelActivityIndicator.stopAnimating()
        }
        
        // Refresh the user image if it exists
        if let userImage = Constants.Data.currentUser.userImage
        {
            self.displayUserImage.image = userImage
            self.displayUserImageActivityIndicator.stopAnimating()
            
            // Store the new image in Core Data for immediate access in next VC loading
            CoreDataFunctions().currentUserSave(user: Constants.Data.currentUser)
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
                case _ as AWSGetSingleUserData:
                    if success
                    {
                        // Refresh the user elements
                        self.refreshCurrentUserElements()
                        
                        // Refresh child VCs
                        if self.blobVC != nil
                        {
                            self.blobVC.refreshBlobViewTable()
                        }
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case _ as FBGetUserData:
                    // Do not distinguish between success and failure for this class - both need to have the userList updated
                    // Refresh the user elements
                    self.refreshCurrentUserElements()
                case _ as AWSDeleteBlob:
                    if !success
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case _ as AWSGetUserBlobs:
                    if success
                    {
                        if Constants.Data.userBlobs.count <= 0
                        {
                            // The User has not created any Blobs, so stop the loading animation and show the message
//                            self.blobUserActivityIndicator.stopAnimating()
                            self.blobsTableViewBackgroundLabel.text = "You have not yet created a Blob.  Tap the add button on the Map Screen to create a new Blob!"
                        }
                        else
                        {
                            // Assign the global User Blobs to the local array
                            self.userBlobs = Constants.Data.userBlobs
                            
                            // Refresh the Table View
                            self.blobsUserTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
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
                        // Find the correct User Object in the local list and assign the newly downloaded Image
                        loopLocalUserObjectCheck: for blobObject in self.userBlobs
                        {
                            if blobObject.blobID == awsGetThumbnailImage.blob.blobID
                            {
                                blobObject.blobThumbnail = awsGetThumbnailImage.blob.blobThumbnail
                                
                                break loopLocalUserObjectCheck
                            }
                        }
                        
                        print("ADDED IMAGE: \(awsGetThumbnailImage.blob.blobThumbnailID))")
                        
                        // Reload the Table View
                        print("GET IMAGE - RELOAD TABLE VIEW")
                        self.blobsUserTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
                        
                        // Find the correct User Object in the global list and assign the newly downloaded Image
                        loopGlobalUserObjectCheck: for blobObject in Constants.Data.userBlobs
                        {
                            if blobObject.blobID == awsGetThumbnailImage.blob.blobID
                            {
                                blobObject.blobThumbnail = awsGetThumbnailImage.blob.blobThumbnail
                                
                                break loopGlobalUserObjectCheck
                            }
                        }
                        
                        // Refresh child VCs
                        if self.blobVC != nil
                        {
                            self.blobVC.refreshBlobViewTable()
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
