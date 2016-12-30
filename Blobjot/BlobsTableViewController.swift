//
//  BlobsTableViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 12/23/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import UIKit

class BlobsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AWSRequestDelegate
{
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var tabBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    var viewContainer: UIView!
    var statusBarView: UIView!
    var tableFilterContainer: UIView!
    var tableFilter1: UIView!
    var tableFilter2: UIView!
    var tableFilter4: UIView!
    var tableFilterLabel1: UILabel!
    var tableFilterLabel2: UILabel!
    var tableFilterLabel4: UILabel!
    var tableFilterClear: UILabel!
    var blobsTableViewBackgroundLabel: UILabel!
    var blobsTableView: UITableView!
    
    var tableFilter1TapGesture: UITapGestureRecognizer!
    var tableFilter2TapGesture: UITapGestureRecognizer!
    var tableFilter4TapGesture: UITapGestureRecognizer!
    var tableFilterClearTapGesture: UITapGestureRecognizer!
    
    // Create a local property to hold the child VC
    var blobVC: BlobTableViewController!
    
    // Create a custom array of Blobs to exclude invisible Blobs
    var visibleBlobs = [Blob]()
    
    // Create a toggle indicator for filtering the Public Blobs by Interest only
    var publicBlobsInterestOnly: Bool = false
    
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
        
        tableFilterContainer = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: 60))
        tableFilterContainer.backgroundColor = Constants.Colors.colorStatusBarLight
        viewContainer.addSubview(tableFilterContainer)
        
        let constantsInstance = Constants()
        let tableFilterCircleSize: CGFloat = 50
        let tableHalf: CGFloat = tableFilterContainer.frame.width / 2
        let tableFilterYOffset: CGFloat = (tableFilterContainer.frame.height - tableFilterCircleSize) / 2
        tableFilter1 = UIView(frame: CGRect(x: tableHalf - 20 - tableFilterCircleSize * 1.5, y: tableFilterYOffset, width: tableFilterCircleSize, height: tableFilterCircleSize))
        tableFilter1.backgroundColor = constantsInstance.blobColorOpaque(Constants.BlobTypes.temporary, mainMap: false)
        tableFilter1.layer.cornerRadius = tableFilterCircleSize / 2
        tableFilter1.layer.shadowOffset = CGSize(width: 0, height: 0.2)
        tableFilter1.layer.shadowOpacity = 0.2
        tableFilter1.layer.shadowRadius = 1.0
        tableFilterContainer.addSubview(tableFilter1)
        
        tableFilterLabel1 = UILabel(frame: CGRect(x: 0, y: 0, width: tableFilterCircleSize, height: tableFilterCircleSize))
        tableFilterLabel1.font = UIFont(name: Constants.Strings.fontRegular, size: 8)
        tableFilterLabel1.textColor = Constants.Colors.colorTextWhite
        tableFilterLabel1.textAlignment = .center
        tableFilterLabel1.numberOfLines = 1
        tableFilterLabel1.lineBreakMode = NSLineBreakMode.byWordWrapping
        tableFilterLabel1.text = "Temporary"
        tableFilter1.addSubview(tableFilterLabel1)
        
        tableFilter2 = UIView(frame: CGRect(x: tableHalf - tableFilterCircleSize / 2, y: tableFilterYOffset, width: tableFilterCircleSize, height: tableFilterCircleSize))
        tableFilter2.backgroundColor = constantsInstance.blobColorOpaque(Constants.BlobTypes.permanent, mainMap: false)
        tableFilter2.layer.cornerRadius = tableFilterCircleSize / 2
        tableFilter2.layer.shadowOffset = CGSize(width: 0, height: 0.2)
        tableFilter2.layer.shadowOpacity = 0.2
        tableFilter2.layer.shadowRadius = 1.0
        tableFilterContainer.addSubview(tableFilter2)
        
        tableFilterLabel2 = UILabel(frame: CGRect(x: 0, y: 0, width: tableFilterCircleSize, height: tableFilterCircleSize))
        tableFilterLabel2.font = UIFont(name: Constants.Strings.fontRegular, size: 8)
        tableFilterLabel2.textColor = Constants.Colors.colorTextWhite
        tableFilterLabel2.textAlignment = .center
        tableFilterLabel2.numberOfLines = 1
        tableFilterLabel2.lineBreakMode = NSLineBreakMode.byWordWrapping
        tableFilterLabel2.text = "Permanent"
        tableFilter2.addSubview(tableFilterLabel2)
        
        tableFilter4 = UIView(frame: CGRect(x: tableHalf + 20 + tableFilterCircleSize / 2, y: tableFilterYOffset, width: tableFilterCircleSize, height: tableFilterCircleSize))
        tableFilter4.backgroundColor = constantsInstance.blobColorOpaque(Constants.BlobTypes.blobjot, mainMap: false)
        tableFilter4.layer.cornerRadius = tableFilterCircleSize / 2
        tableFilter4.layer.shadowOffset = CGSize(width: 0, height: 0.2)
        tableFilter4.layer.shadowOpacity = 0.2
        tableFilter4.layer.shadowRadius = 1.0
        tableFilterContainer.addSubview(tableFilter4)
        
        tableFilterLabel4 = UILabel(frame: CGRect(x: 0, y: 0, width: tableFilterCircleSize, height: tableFilterCircleSize))
        tableFilterLabel4.font = UIFont(name: Constants.Strings.fontRegular, size: 8)
        tableFilterLabel4.textColor = Constants.Colors.colorTextWhite
        tableFilterLabel4.textAlignment = .center
        tableFilterLabel4.numberOfLines = 1
        tableFilterLabel4.lineBreakMode = NSLineBreakMode.byWordWrapping
        tableFilterLabel4.text = "Public"
        tableFilter4.addSubview(tableFilterLabel4)
        
        tableFilterClear = UILabel(frame: CGRect(x: tableHalf + 30 + tableFilterCircleSize * 1.5, y: tableFilterYOffset, width: tableFilterCircleSize, height: tableFilterCircleSize))
        tableFilterClear.font = UIFont(name: Constants.Strings.fontRegular, size: 24)
        tableFilterClear.textColor = Constants.Colors.colorTextWhite
        tableFilterClear.textAlignment = .center
        tableFilterClear.numberOfLines = 1
        tableFilterClear.lineBreakMode = NSLineBreakMode.byWordWrapping
        tableFilterClear.text = "\u{2573}"
        tableFilterClear.isUserInteractionEnabled = true
        tableFilterClear.isHidden = true
        tableFilterContainer.addSubview(tableFilterClear)
        
        resetBlobsList(false)
        
        blobsTableViewBackgroundLabel = UILabel(frame: CGRect(x: 10, y: 10, width: viewContainer.frame.width - 20, height: Constants.Dim.blobsActiveTableViewCellHeight - 20))
        blobsTableViewBackgroundLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 20)
        if visibleBlobs.count <= 1
        {
            blobsTableViewBackgroundLabel.text = "Please check your network connection or sign out and sign in again."
        }
        blobsTableViewBackgroundLabel.numberOfLines = 0
        blobsTableViewBackgroundLabel.lineBreakMode = .byWordWrapping
        blobsTableViewBackgroundLabel.textColor = Constants.Colors.colorTextStandard
        blobsTableViewBackgroundLabel.textAlignment = .center
        viewContainer.addSubview(blobsTableViewBackgroundLabel)
        
        blobsTableView = UITableView(frame: CGRect(x: 0, y: tableFilterContainer.frame.height, width: viewContainer.frame.width, height: viewContainer.frame.height - tableFilterContainer.frame.height))
        blobsTableView.dataSource = self
        blobsTableView.delegate = self
        blobsTableView.register(BlobsTableViewCell.self, forCellReuseIdentifier: Constants.Strings.blobsTableViewCellReuseIdentifier)
        blobsTableView.separatorStyle = .none
        blobsTableView.backgroundColor = UIColor.clear
        blobsTableView.alwaysBounceVertical = true
        blobsTableView.showsVerticalScrollIndicator = false
        blobsTableView.allowsSelection = true
        viewContainer.addSubview(blobsTableView)
        
        // Add the Status Bar, Top Bar and Search Bar
        statusBarView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 20))
        statusBarView.backgroundColor = Constants.Colors.colorStatusBar
        self.view.addSubview(statusBarView)
        
        tableFilter1TapGesture = UITapGestureRecognizer(target: self, action: #selector(BlobsTableViewController.tapTableFilter1(_:)))
        tableFilter1TapGesture.numberOfTapsRequired = 1  // add single tap
        tableFilter1.addGestureRecognizer(tableFilter1TapGesture)
        
        tableFilter2TapGesture = UITapGestureRecognizer(target: self, action: #selector(BlobsTableViewController.tapTableFilter2(_:)))
        tableFilter2TapGesture.numberOfTapsRequired = 1  // add single tap
        tableFilter2.addGestureRecognizer(tableFilter2TapGesture)
        
        tableFilter4TapGesture = UITapGestureRecognizer(target: self, action: #selector(BlobsTableViewController.tapTableFilter4(_:)))
        tableFilter4TapGesture.numberOfTapsRequired = 1  // add single tap
        tableFilter4.addGestureRecognizer(tableFilter4TapGesture)
        
        tableFilterClearTapGesture = UITapGestureRecognizer(target: self, action: #selector(BlobsTableViewController.tapTableFilterClear(_:)))
        tableFilterClearTapGesture.numberOfTapsRequired = 1  // add single tap
        tableFilterClear.addGestureRecognizer(tableFilterClearTapGesture)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: GESTURE RECOGNIZERS
    
    func tapMapView(_ gesture: UITapGestureRecognizer)
    {
        self.presentingViewController!.dismiss(animated: true, completion: {})
    }
    
    
    // MARK: TABLE VIEW DATA SOURCE
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // The Map Blobs array holds the "default" Blob as the first element, so only show the count of the array minus one
        return visibleBlobs.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return Constants.Dim.blobsTableViewCellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.blobsTableViewCellReuseIdentifier, for: indexPath) as! BlobsTableViewCell
        
        // Add a clear background for the selectedBackgroundView so that the row is not highlighted when selected
        let sbv = UIView(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height))
        sbv.backgroundColor = UIColor.clear
        cell.selectedBackgroundView = sbv
        
        // Clear the content, if needed
        cell.cellUserImage.image = nil
        cell.cellThumbnail.image = nil
        
        // Start animating the activity indicators
        cell.userImageActivityIndicator.startAnimating()
        cell.thumbnailActivityIndicator.startAnimating()
        
        // Convert to NSIndexPath
        let blobIndex = (indexPath as NSIndexPath).row
        
        // Be sure the Map Blobs array has an element at the assigned Blob Index
        if visibleBlobs.count >= blobIndex
        {
            // If the Blob is a Blobjot (Public) Blob, do not try to find the user - set the username as custom text
            if visibleBlobs[blobIndex].blobType == Constants.BlobTypes.blobjot
            {
                cell.cellUserImage.image = UIImage(named: "BLOBJOT_purple.png")
                cell.userImageActivityIndicator.stopAnimating()
                
                cell.cellUserName.text = "Public Area"
            }
            else
            {
                // Find the correct User Object in the global list and assign the User Image
                loopUserObjectCheck: for userObject in Constants.Data.userObjects
                {
                    if userObject.userID == visibleBlobs[blobIndex].blobUserID
                    {
                        if userObject.userImage != nil
                        {
                            cell.cellUserImage.image = userObject.userImage
                            cell.userImageActivityIndicator.stopAnimating()
                            
                            cell.cellUserName.text = userObject.userName
                        }
                        break loopUserObjectCheck
                    }
                }
            }
            cell.cellBlobTypeIndicator.backgroundColor = Constants().blobColorOpaque(visibleBlobs[blobIndex].blobType, mainMap: false)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "E, MMM d HH:mm"
            let stringDate: String = formatter.string(from: visibleBlobs[blobIndex].blobDatetime as Date)
            cell.cellDatetime.text = stringDate
            
            if let thumbnailID = visibleBlobs[blobIndex].blobThumbnailID
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
                if let blobText = visibleBlobs[blobIndex].blobText
                {
                    cell.cellText.text = blobText
                    cell.cellText.textColor = Constants.Colors.colorTextStandard
                }
                else
                {
                    cell.cellText.text = "Not in\nRange"
                    cell.cellText.textColor = Constants.Colors.colorTextRed
                }
                
                // Stop animating the activity indicator
                cell.thumbnailActivityIndicator.stopAnimating()
            }
        }
        else
        {
            print("THE MAP BLOBS ARRAY DOES NOT HAVE AN ELEMENT AT INDEX: \(blobIndex)")
        }
        
        return cell
    }
    
    // The Table Row slide action methods
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        // Convert to NSIndexPath
        let blobIndex = (indexPath as NSIndexPath).row
        
        // If the user selects to hide the Blob from their map
        let hide = UITableViewRowAction(style: .normal, title: "Hide\nBlob")
        { action, index in
//            // Find the Blob for the selected table row
//            let actionBlob = Constants.Data.locationBlobs[blobIndex]
//            
//            // Remove the Blob from the locationBlobs array (so it disappears from the Table View)
//            Constants.Data.locationBlobs.remove(at: blobIndex)
//            
//            // Refresh the Table View to no longer show that row
//            self.blobsActiveTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
//            
//            // Record the Blob hide in AWS so that the Blob no longer is downloaded for this user
//            AWSPrepRequest(requestToCall: AWSHideBlob(blobID: actionBlob.blobID, userID: Constants.Data.currentUser.userID!), delegate: self as AWSRequestDelegate).prepRequest()
//            
//            // Remove the Blob from the tagged Blobs
//            loopTaggedBlobsCheck: for (tIndex, blob) in Constants.Data.taggedBlobs.enumerated()
//            {
//                if blob.blobID == actionBlob.blobID
//                {
//                    Constants.Data.taggedBlobs.remove(at: tIndex)
//                    
//                    break loopTaggedBlobsCheck
//                }
//            }
//            
//            // Remove the Blob from the map Blobs
//            loopMapBlobsCheck: for (bIndex, blob) in Constants.Data.mapBlobs.enumerated()
//            {
//                if blob.blobID == actionBlob.blobID
//                {
//                    Constants.Data.mapBlobs.remove(at: bIndex)
//                    
//                    break loopMapBlobsCheck
//                }
//            }
//            
//            // Remove the Circle for this Blob from the map Circles so that it no longer shows on the Map View
//            loopMapCirclesCheck: for (cIndex, circle) in Constants.Data.mapCircles.enumerated()
//            {
//                if circle.title == actionBlob.blobID
//                {
//                    circle.map = nil
//                    Constants.Data.mapCircles.remove(at: cIndex)
//                    
//                    break loopMapCirclesCheck
//                }
//            }
        }
        hide.backgroundColor = Constants.Colors.blobRedOpaque
        
        return [hide]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        // Prevent the row from being highlighted
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Load the Blob View Controller with the selected Blob
        if visibleBlobs.count >= (indexPath as NSIndexPath).row
        {
            self.loadBlobViewWithBlob(visibleBlobs[(indexPath as NSIndexPath).row])
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
    
    
    // MARK: TAP GESTURES
    
    // If the tapTableFilter1 button is tapped, filter the All Blobs table
    func tapTableFilter1(_ gesture: UITapGestureRecognizer)
    {
        print("BTVC - TABLE FILTER 1")
        filterTableFor(Constants.BlobTypes.temporary)
    }
    func tapTableFilter2(_ gesture: UITapGestureRecognizer)
    {
        print("BTVC - TABLE FILTER 2")
        filterTableFor(Constants.BlobTypes.permanent)
    }
    func tapTableFilter4(_ gesture: UITapGestureRecognizer)
    {
        print("BTVC - TABLE FILTER 4")
        if !publicBlobsInterestOnly
        {
            filterTableFor(Constants.BlobTypes.blobjot)
            
            // Indicate that the Public Blobs filter is showing all Public Blobs, but the next selection will filter for interest only
            publicBlobsInterestOnly = true
            tableFilterLabel4.text = "Interests"
        }
        else
        {
            filterTableFor(Constants.BlobTypes.blobjot)
            
            // Indicate that the Public Blobs filter is showing interest only Blobs, but the next selection will filter for all Public Blobs
            publicBlobsInterestOnly = false
            tableFilterLabel4.text = "Public"
        }
    }
    func tapTableFilterClear(_ gesture: UITapGestureRecognizer)
    {
        print("BTVC - TABLE FILTER CLEAR")
        resetBlobsList(true)
        
        // Reset the Public Blobs filter and button text
        publicBlobsInterestOnly = false
        tableFilterLabel4.text = "Public"
    }
    
    
    // MARK: CUSTOM FUNCTIONS
    
    // Filter the table content
    func filterTableFor(_ blobType: Constants.BlobTypes)
    {
        print("BTVC - FILTER TABLE FOR: \(blobType)")
        visibleBlobs = [Blob]()
        for blob in Constants.Data.mapBlobs
        {
            if blob.blobType == blobType
            {
                visibleBlobs.append(blob)
            }
        }
        
        // Show the clear filter indicator
        tableFilterClear.isHidden = false
        
        reloadTableView()
    }
    
    // Reset the visibleBlobs list (Blobs from mapBlobs without invisible Blobs)
    func resetBlobsList(_ reloadTable: Bool)
    {
        visibleBlobs = [Blob]()
        for blob in Constants.Data.mapBlobs
        {
            if blob.blobType != Constants.BlobTypes.invisible
            {
                visibleBlobs.append(blob)
            }
        }
        
        // Hide the clear filter indicator
        tableFilterClear.isHidden = true
        
        // Only reload the table if indicated (otherwise the table may still be nil)
        if reloadTable
        {
            reloadTableView()
        }
    }
    
    // Reload the Table View
    func reloadTableView()
    {
        print("BTVC - RELOAD TABLE")
        // Reload the Collection View
        self.blobsTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
    }
    
    // Dismiss the latest View Controller presented from this VC
    // This version is used when the top VC is popped from a Nav Bar button
    func popViewController(_ sender: UIBarButtonItem)
    {
        self.navigationController!.popViewController(animated: true)
    }
    
    func loadBlobViewWithBlob(_ blob: Blob)
    {
        if blob.blobExtraRequested && (blob.blobText != nil || blob.blobThumbnailID != nil)
        {
            // Create a back button and title for the Nav Bar
            let backButtonItem = UIBarButtonItem(title: "\u{2190}",
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
            ncTitleText.font = UIFont(name: Constants.Strings.fontRegular, size: 14)
            ncTitleText.textColor = Constants.Colors.colorTextNavBar
            ncTitleText.textAlignment = .center
            ncTitle.addSubview(ncTitleText)
            
            // Instantiate the BlobViewController and pass the Preview Blob to the VC
            blobVC = BlobTableViewController()
            blobVC.blob = blob
            
            // Assign the created Nav Bar settings to the Tab Bar Controller
            blobVC.navigationItem.setLeftBarButton(backButtonItem, animated: true)
            blobVC.navigationItem.titleView = ncTitle
            
            if let navController = self.navigationController
            {
                navController.pushViewController(blobVC, animated: true)
            }
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
