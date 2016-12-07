//
//  ListTableViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 7/26/16.
//  Copyright © 2016 tangojlabs. All rights reserved.
//

import AWSLambda
import UIKit

class BlobsActiveTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AWSRequestDelegate
{
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var tabBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    var viewContainer: UIView!
    var statusBarView: UIView!
    var blobsTableViewBackgroundLabel: UILabel!
    var blobsActiveTableView: UITableView!
    
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
        
        blobsTableViewBackgroundLabel = UILabel(frame: CGRect(x: 10, y: 10, width: viewContainer.frame.width - 20, height: Constants.Dim.blobsActiveTableViewCellHeight - 20))
        blobsTableViewBackgroundLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 20)
        if Constants.Data.locationBlobs.count <= 1
        {
            blobsTableViewBackgroundLabel.text = "There are no Blobs at your location.  Use the Map screen to find some in your area!"
        }
        blobsTableViewBackgroundLabel.numberOfLines = 0
        blobsTableViewBackgroundLabel.lineBreakMode = .byWordWrapping
        blobsTableViewBackgroundLabel.textColor = Constants.Colors.colorTextStandard
        blobsTableViewBackgroundLabel.textAlignment = .center
        viewContainer.addSubview(blobsTableViewBackgroundLabel)
        
        blobsActiveTableView = UITableView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        blobsActiveTableView.dataSource = self
        blobsActiveTableView.delegate = self
        blobsActiveTableView.register(BlobsActiveTableViewCell.self, forCellReuseIdentifier: Constants.Strings.blobsActiveTableViewCellReuseIdentifier)
        blobsActiveTableView.separatorStyle = .none
        blobsActiveTableView.backgroundColor = UIColor.clear
        blobsActiveTableView.alwaysBounceVertical = true
        blobsActiveTableView.showsVerticalScrollIndicator = false
        blobsActiveTableView.allowsSelection = true
        viewContainer.addSubview(blobsActiveTableView)
        
//        self.tableView.registerClass(ListTableViewCell.self, forCellReuseIdentifier: Constants.Strings.listTableViewCellReuseIdentifier)
//        self.tableView.contentInset = UIEdgeInsets(top: statusBarHeight, left: 0, bottom: 0, right: 0)
        
        // Add the Status Bar, Top Bar and Search Bar
        statusBarView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 20))
        statusBarView.backgroundColor = Constants.Colors.colorStatusBar
        self.view.addSubview(statusBarView)

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: GESTURE RECOGNIZERS

    func tapMapView(_ gesture: UITapGestureRecognizer)
    {
        self.presentingViewController!.dismiss(animated: true, completion: {})
    }
    
    
    // MARK: TABLE VIEW DATA SOURCE

    func numberOfSections(in tableView: UITableView) -> Int
    {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // The Location Blobs array holds the "default" Blob as the first element, so only show the count of the array minus one
        return Constants.Data.locationBlobs.count - 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return Constants.Dim.blobsActiveTableViewCellHeight
    }

    // When loading the Table View Content for Location Blobs, exclude the first element (the "default" Blob), so be sure to advance the indexPath + 1 for the
    // Location Blobs array
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.blobsActiveTableViewCellReuseIdentifier, for: indexPath) as! BlobsActiveTableViewCell
        
        // Add a clear background for the selectedBackgroundView so that the row is not highlighted when selected
        let sbv = UIView(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height))
        sbv.backgroundColor = UIColor.clear
        cell.selectedBackgroundView = sbv
        
        // Clear the content, if needed
        cell.cellThumbnail.image = nil
        
        // Start animating the activity indicators
        cell.userImageActivityIndicator.startAnimating()
        cell.thumbnailActivityIndicator.startAnimating()
        
        // Compensate for the "default" Blob as the first element in the Location Blobs array
        let blobIndex = (indexPath as NSIndexPath).row + 1
        
        // Be sure the Location Blobs array has an element at the assigned Blob Index
        if Constants.Data.locationBlobs.count >= blobIndex
        {
            // Find the correct User Object in the global list and assign the User Image
            loopUserObjectCheck: for userObject in Constants.Data.userObjects
            {
                if userObject.userID == Constants.Data.locationBlobs[blobIndex].blobUserID
                {
                    if userObject.userImage != nil
                    {
                        cell.cellUserImage.image = userObject.userImage
                        cell.userImageActivityIndicator.stopAnimating()
                    }
                    break loopUserObjectCheck
                }
            }
            cell.cellBlobTypeIndicator.backgroundColor = Constants().blobColorOpaque(Constants.Data.locationBlobs[blobIndex].blobType, mainMap: false)
            cell.cellUserName.text = Constants.Data.locationBlobs[blobIndex].blobText
            
            let formatter = DateFormatter()
            formatter.dateFormat = "E, MMM d HH:mm"
            let stringDate: String = formatter.string(from: Constants.Data.locationBlobs[blobIndex].blobDatetime as Date)
            cell.cellDatetime.text = stringDate
            
            if let thumbnailID = Constants.Data.locationBlobs[blobIndex].blobThumbnailID
            {
                // Loop through the BlobThumbnailObjects array
                for tObject in Constants.Data.blobThumbnailObjects
                {
                    // Check each thumbnail object to see if matches
                    if tObject.blobThumbnailID == thumbnailID
                    {
                        // Check to make sure the thumbnail has already been downloaded
                        if let thumbnailImage = tObject.blobThumbnail
                        {
                            // Setthe Preview Thumbnail image
                            cell.cellThumbnail.image = thumbnailImage
                            
                            // Stop animating the activity indicator
                            cell.thumbnailActivityIndicator.stopAnimating()
                        }
                    }
                }
            }
            else
            {
                cell.cellText.text = Constants.Data.locationBlobs[blobIndex].blobText
                
                // Stop animating the activity indicator
                cell.thumbnailActivityIndicator.stopAnimating()
            }
        }
        else
        {
            print("THE LOCATION BLOBS ARRAY DOES NOT HAVE AN ELEMENT AT INDEX: \(blobIndex)")
        }
        
        return cell
    }
    
    // The Table Row slide action methods
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        // Compensate for the "default" Blob as the first element in the Location Blobs array
        let blobIndex = (indexPath as NSIndexPath).row + 1
        
        // If the user selects to hide the Blob from their map
        let hide = UITableViewRowAction(style: .normal, title: "Hide\nBlob")
        { action, index in
            // Find the Blob for the selected table row
            let actionBlob = Constants.Data.locationBlobs[blobIndex]
            
            // Remove the Blob from the locationBlobs array (so it disappears from the Table View)
            Constants.Data.locationBlobs.remove(at: blobIndex)
            
            // Refresh the Table View to no longer show that row
            self.blobsActiveTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
            
            // Record the Blob hide in AWS so that the Blob no longer is downloaded for this user
            AWSPrepRequest(requestToCall: AWSHideBlob(blobID: actionBlob.blobID, userID: Constants.Data.currentUser.userID!), delegate: self as AWSRequestDelegate).prepRequest()
            
            // Remove the Blob from the tagged Blobs
            loopTaggedBlobsCheck: for (tIndex, blob) in Constants.Data.taggedBlobs.enumerated()
            {
                if blob.blobID == actionBlob.blobID
                {
                    Constants.Data.taggedBlobs.remove(at: tIndex)
                    
                    break loopTaggedBlobsCheck
                }
            }
            
            // Remove the Blob from the map Blobs
            loopMapBlobsCheck: for (bIndex, blob) in Constants.Data.mapBlobs.enumerated()
            {
                if blob.blobID == actionBlob.blobID
                {
                    Constants.Data.mapBlobs.remove(at: bIndex)
                    
                    break loopMapBlobsCheck
                }
            }
            
            // Remove the Circle for this Blob from the map Circles so that it no longer shows on the Map View
            loopMapCirclesCheck: for (cIndex, circle) in Constants.Data.mapCircles.enumerated()
            {
                if circle.title == actionBlob.blobID
                {
                    circle.map = nil
                    Constants.Data.mapCircles.remove(at: cIndex)
                    
                    break loopMapCirclesCheck
                }
            }
        }
        hide.backgroundColor = Constants.Colors.blobRedOpaque
        
        return [hide]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        // Prevent the row from being highlighted
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Load the Blob View Controller with the selected Blob - remember to add one to the Location Blob array since
        // the first element (the "default" Blob is not shown in the Collection View
        if Constants.Data.locationBlobs.count >= (indexPath as NSIndexPath).row + 1
        {
            self.loadBlobViewWithBlob(Constants.Data.locationBlobs[(indexPath as NSIndexPath).row + 1])
        }
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath)
    {
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath)
    {
    }
    
    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
    }
    
    
    // MARK: CUSTOM FUNCTIONS
    
    // Reload the Table View
    func reloadTableView()
    {
        // Reload the Collection View
        self.blobsActiveTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
    }
    
    // Dismiss the latest View Controller presented from this VC
    // This version is used when the top VC is popped from a Nav Bar button
    func popViewController(_ sender: UIBarButtonItem)
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    func loadBlobViewWithBlob(_ blob: Blob)
    {
        if blob.blobExtraRequested && (blob.blobText != nil || blob.blobThumbnailID != nil)
        {
            // Create a back button and title for the Nav Bar
            let backButtonItem = UIBarButtonItem(title: "BLOBS \u{2193}",
                                                 style: UIBarButtonItemStyle.plain,
                                                 target: self,
                                                 action: #selector(BlobsActiveTableViewController.popViewController(_:)))
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
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("BAVC - SHOW LOGIN SCREEN")
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
        DispatchQueue.main.async(execute:
            {
                // Process the return data based on the method used
                switch objectType
                {
                case _ as AWSHideBlob:
                    if !success
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                default:
                    print("BATVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    // Show the error message
                    let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    self.present(alertController, animated: true, completion: nil)
                }
        })
    }
 
}
