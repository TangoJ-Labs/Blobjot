//
//  MyBlobsTableViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 7/27/16.
//  Copyright © 2016 tangojlabs. All rights reserved.
//

import AWSLambda
import AWSS3
import UIKit

class BlobsUserTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AWSRequestDelegate {
    
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var tabBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    var viewContainer: UIView!
    var statusBarView: UIView!
    var blobUserActivityIndicator: UIActivityIndicatorView!
    var blobsTableViewBackgroundLabel: UILabel!
    var blobsUserTableView: UITableView!
    
    var userBlobs = [Blob]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Device and Status Bar Settings
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        print("**************** BUTV - STATUS BAR HEIGHT: \(statusBarHeight)")
        if let navBarHeight = self.navigationController?.navigationBar.frame.height {
            print("NAV BAR HEIGHT DYNAMIC: \(navBarHeight)")
            self.navBarHeight = navBarHeight
//            self.statusBarHeight = 0
        } else {
            self.navBarHeight = 44
        }
        print("**************** BUTV - NAV BAR HEIGHT: \(navBarHeight)")
        viewFrameY = self.view.frame.minY
        print("**************** BUTV - VIEW FRAME Y: \(viewFrameY)")
        screenSize = UIScreen.main.bounds
        print("**************** BUTV - SCREEN HEIGHT: \(screenSize.height)")
        print("**************** BUTV - VIEW HEIGHT: \(self.view.frame.height)")
        if let tabBarHeight = self.navigationController?.navigationBar.frame.height {
            self.tabBarHeight = tabBarHeight
        } else {
            self.tabBarHeight = 49
        }
        print("**************** BUTV - TAB BAR HEIGHT: \(self.tabBarController?.tabBar.frame.height)")
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: statusBarHeight + navBarHeight - viewFrameY, width: self.view.frame.width, height: self.view.frame.height - statusBarHeight - navBarHeight - tabBarHeight + viewFrameY))
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        self.view.addSubview(viewContainer)
        print("**************** BUTV - VIEW CONTAINER FRAME Y: \(viewContainer.frame.minY)")
        
        // Add a loading indicator while downloading the logged in user image
        blobUserActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: Constants.Dim.blobsUserTableViewCellHeight))
        blobUserActivityIndicator.color = UIColor.black
        viewContainer.addSubview(blobUserActivityIndicator)
        blobUserActivityIndicator.startAnimating()
        
        blobsTableViewBackgroundLabel = UILabel(frame: CGRect(x: 10, y: 10, width: viewContainer.frame.width - 20, height: Constants.Dim.blobsUserTableViewCellHeight - 20))
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
        blobsUserTableView.register(BlobsUserTableViewCell.self, forCellReuseIdentifier: Constants.Strings.blobsUserTableViewCellReuseIdentifier)
        blobsUserTableView.separatorStyle = .none
        blobsUserTableView.backgroundColor = UIColor.clear
        blobsUserTableView.alwaysBounceVertical = true
        blobsUserTableView.showsVerticalScrollIndicator = false
        viewContainer.addSubview(blobsUserTableView)
        
//        self.tableView.registerClass(ListTableViewCell.self, forCellReuseIdentifier: Constants.Strings.listTableViewCellReuseIdentifier)
//        self.tableView.contentInset = UIEdgeInsets(top: statusBarHeight, left: 0, bottom: 0, right: 0)
        
        // Add the Status Bar, Top Bar and Search Bar
        statusBarView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 20))
        statusBarView.backgroundColor = Constants.Colors.colorStatusBar
        self.view.addSubview(statusBarView)
        
        // Request the Blobs that the user has posted
        blobUserActivityIndicator.startAnimating()
        AWSPrepRequest(requestToCall: AWSGetUserBlobs(), delegate: self as AWSRequestDelegate).prepRequest()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return userBlobs.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.Dim.blobsActiveTableViewCellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.blobsUserTableViewCellReuseIdentifier, for: indexPath) as! BlobsUserTableViewCell
        
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
        let cellBlob = userBlobs[(indexPath as NSIndexPath).row]
        
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
        if let thumbnail = cellBlob.blobThumbnail {
            cell.cellThumbnail.image = thumbnail
        } else {
            cell.cellText.text = cellBlob.blobText
            
            // Request the thumbnail image if the thumbnailID exists
            if cellBlob.blobThumbnailID != nil {
                AWSPrepRequest(requestToCall: AWSGetThumbnailImage(blob: cellBlob), delegate: self as AWSRequestDelegate).prepRequest()
            }
        }
        
        return cell
    }
    
    
    // For the slide action to delete the Blob
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        // Retrieve the Blob associated with this cell
        let cellBlob = userBlobs[(indexPath as NSIndexPath).row]
        
        // Create a dummy action to add to the initial action array
        let actionReturn = UITableViewRowAction()
        var actionReturnArray = [actionReturn]
        
        // If the row's Blob is a Permanent Blob, allow deletion.  Otherwise, show the error message and DO NOT allow deletion
        if cellBlob.blobType == Constants.BlobTypes.permanent {
            let delete = UITableViewRowAction(style: .normal, title: "Delete\nBlob") { action, index in
                print("delete button tapped")
                
                // Remove the Blob from the userBlobs array (so it disappears from the Table View)
                self.userBlobs.remove(at: (indexPath as NSIndexPath).row)
                
                // Refresh the Table View to no longer show that row
                self.blobsUserTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
                
                // Record the Blob deletion in AWS so that the Blob no longer is downloaded for anyone
                AWSPrepRequest(requestToCall: AWSDeleteBlob(blobID: cellBlob.blobID, userID: Constants.Data.currentUser), delegate: self as AWSRequestDelegate).prepRequest()
                
                // Remove the Circle for this Blob from the map Circles so that it no longer shows on the Map View
                loopMapCirclesCheck: for (cIndex, circle) in Constants.Data.mapCircles.enumerated() {
                    if circle.title == cellBlob.blobID {
                        print("DELETING CIRCLE: \(circle.title)")
                        circle.map = nil
                        Constants.Data.mapCircles.remove(at: cIndex)
                        
                        break loopMapCirclesCheck
                    }
                }
            }
            delete.backgroundColor = UIColor.red
            actionReturnArray = [delete]
        } else {
            createAlertOkView("Uh oh!", message: "Sorry, you can only delete permanent blobs.")
        }
        
        return actionReturnArray
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("DID SELECT ROW #\((indexPath as NSIndexPath).item)!")
        
        // Prevent the row from being highlighted
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Load the Blob View Controller with the selected Blob
        print("USER BLOB COUNT: \(userBlobs.count)")
        if userBlobs.count >= (indexPath as NSIndexPath).row {
            self.loadBlobViewWithBlob(userBlobs[(indexPath as NSIndexPath).row])
        }
        
        // Reference the cell and start the loading indicator
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.blobsUserTableViewCellReuseIdentifier, for: indexPath) as! BlobsUserTableViewCell
        print("SELECTED CELL \((indexPath as NSIndexPath).row): \(cell)")
        cell.cellSelectedActivityIndicator.startAnimating()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        print("DID DESELECT ROW: \((indexPath as NSIndexPath).row)")
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        print("DID HIGHLIGHT ROW: \((indexPath as NSIndexPath).row)")
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        print("DID UNHIGHLIGHT ROW: \((indexPath as NSIndexPath).row)")
    }
    
    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
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
    func popViewController(_ sender: UIBarButtonItem) {
        print("pop Back to Table View")
        self.dismiss(animated: true, completion: nil)
    }
    
    func createAlertOkView(_ title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
            print("OK")
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func loadBlobViewWithBlob(_ blob: Blob) {
        print("LOADING USER LIST BLOB")
        print(blob.blobExtraRequested)
        print(blob.blobText)
        print(blob.blobThumbnailID)
        if blob.blobText != nil || blob.blobThumbnailID != nil {
            
            // Create a back button and title for the Nav Bar
            let backButtonItem = UIBarButtonItem(title: "< List",
                                                 style: UIBarButtonItemStyle.plain,
                                                 target: self,
                                                 action: #selector(BlobsUserTableViewController.popViewController(_:)))
            backButtonItem.tintColor = UIColor.white
            
            let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
            let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
            
            // Find the correct User Object in the global list and assign the userName to the nav bar title
            loopUserObjectCheck: for userObject in Constants.Data.userObjects {
                if userObject.userID == blob.blobUserID {
                    ncTitleText.text = userObject.userName
                    break loopUserObjectCheck
                }
            }
            ncTitleText.textColor = UIColor.white
            ncTitleText.textAlignment = .center
            ncTitle.addSubview(ncTitleText)
            
            // Instantiate the BlobViewController and pass the Preview Blob to the VC
            let blobVC = BlobViewController()
            blobVC.blob = blob
            
            // Instantiate the Nav Controller and attach the Nav Bar items to the view controller settings
            let navController = UINavigationController(rootViewController: blobVC)
            blobVC.navigationItem.setLeftBarButton(backButtonItem, animated: true)
            blobVC.navigationItem.titleView = ncTitle
            
            // Change the Nav Bar color and present the view
            navController.navigationBar.barTintColor = Constants.Colors.colorStatusBar
            self.present(navController, animated: true, completion: nil)
        }
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen() {
        print("BUTVC - SHOW LOGIN SCREEN")
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
        DispatchQueue.main.async(execute:
            {
                // Process the return data based on the method used
                switch objectType
                {
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
                                        self.userBlobs.append(addBlob)
                                        print("APPENDED BLOB: \(addBlob.blobID)")
                                    }
                                }
                                // Sort the User Blobs from newest to oldest
                                self.userBlobs.sort(by: {$0.blobDatetime.timeIntervalSince1970 >  $1.blobDatetime.timeIntervalSince1970})
                                
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
                        loopUserObjectCheck: for blobObject in self.userBlobs {
                            if blobObject.blobID == awsGetThumbnailImage.blob.blobID {
                                blobObject.blobThumbnail = awsGetThumbnailImage.blob.blobThumbnail
                                
                                break loopUserObjectCheck
                            }
                        }
                        
                        print("ADDED IMAGE: \(awsGetThumbnailImage.blob.blobThumbnailID))")
                        
                        // Reload the Table View
                        print("GET IMAGE - RELOAD TABLE VIEW")
                        self.blobsUserTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("AWSGetThumbnailImage Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                default:
                    print("BUTVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    // Show the error message
                    let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    self.present(alertController, animated: true, completion: nil)
                }
        })
    }
    
}
