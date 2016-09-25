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

class BlobsUserTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
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
        
        getUserBlobs()
        
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
            if let thumbnailID = cellBlob.blobThumbnailID {
                getThumbnailImage(cellBlob.blobID, imageKey: thumbnailID)
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
                self.deleteBlob(cellBlob.blobID, userID: Constants.Data.currentUser)
                
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
    
    
    // MARK: AWS METHODS
    
    // Add a record that this Blob was viewed by the logged in user
    func deleteBlob(_ blobID: String, userID: String) {
        print("ADDING BLOB DELETE: \(blobID), \(userID), \(Date().timeIntervalSince1970)")
        let json: NSDictionary = [
            "blob_id"       : blobID
            , "user_id"     : userID
            , "timestamp"   : String(Date().timeIntervalSince1970)
            , "action_type" : "delete"
        ]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-AddBlobAction", jsonObject: json, completionHandler: { (response, err) -> Void in
            
            if (err != nil) {
                print("ADD BLOB DELETE ERROR: \(err)")
            } else if (response != nil) {
                print("BUT-DB: response: \(response)")
            }
        })
    }
    
    // The initial request for User's Blob data - called when the View Controller is instantiated
    func getUserBlobs() {
        print("REQUESTING GUB")
        blobUserActivityIndicator.startAnimating()
        
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["user_id" : Constants.Data.currentUser]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-GetUserBlobs", jsonObject: json, completionHandler: { (response, err) -> Void in
            
            if (err != nil) {
                print("GET USER BLOBS DATA ERROR: \(err)")
            } else if (response != nil) {
                
                // Convert the response to an array of AnyObjects
                if let newUserBlobs = response as? [AnyObject] {
                    print("BUTV-GUB: jsonData: \(newUserBlobs)")
                    print("BLOB COUNT: \(newUserBlobs.count)")
                    
                    if newUserBlobs.count <= 0 {
                        
                        // The User has not created any Blobs, so stop the loading animation and show the message
                        self.blobUserActivityIndicator.stopAnimating()
                        self.blobsTableViewBackgroundLabel.text = "You have not yet created a Blob.  Tap the add button on the Map Screen to create a new Blob!"
                        
                    } else {
                        
                        // Loop through each AnyObject (Blob) in the array
                        for newBlob in newUserBlobs {
                            print("NEW BLOB: \(newBlob)")
                            
                            // Convert the AnyObject to JSON with keys and AnyObject values
                            // Then convert the AnyObject values to Strings or Numbers depending on their key
                            if let checkBlob = newBlob as? [String: AnyObject] {
                                let blobTimestamp = checkBlob["blobTimestamp"] as! Double
                                let blobDatetime = Date(timeIntervalSince1970: blobTimestamp)
                                let blobTypeInt = checkBlob["blobType"] as! Int
                                
                                // Evaluate the blobType Integer received and convert it to the appropriate BlobType Class
                                var blobType: Constants.BlobTypes!
                                switch blobTypeInt {
                                case 1:
                                    blobType = Constants.BlobTypes.temporary
                                case 2:
                                    blobType = Constants.BlobTypes.permanent
                                case 3:
                                    blobType = Constants.BlobTypes.public
                                case 4:
                                    blobType = Constants.BlobTypes.invisible
                                case 5:
                                    blobType = Constants.BlobTypes.sponsoredTemporary
                                case 6:
                                    blobType = Constants.BlobTypes.sponsoredPermanent
                                default:
                                    blobType = Constants.BlobTypes.temporary
                                }
                                
                                // Finish converting the JSON AnyObjects and assign the data to a new Blob Object
                                print("ASSIGNING DATA")
                                let addBlob = Blob()
                                addBlob.blobID = checkBlob["blobID"] as! String
                                addBlob.blobDatetime = blobDatetime
                                addBlob.blobLat = checkBlob["blobLat"] as! Double
                                addBlob.blobLong = checkBlob["blobLong"] as! Double
                                addBlob.blobRadius = checkBlob["blobRadius"] as! Double
                                addBlob.blobType = blobType
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
            
        })
    }
    
    // Download Thumbnail Image
    func getThumbnailImage(_ blobID: String, imageKey: String) {
        print("GETTING IMAGE FOR: \(imageKey)")
        
        let downloadingFilePath = NSTemporaryDirectory() + imageKey // + Constants.Settings.frameImageFileType)
        let downloadingFileURL = URL(fileURLWithPath: downloadingFilePath)
        let transferManager = AWSS3TransferManager.default()
        
        // Download the Frame
        let downloadRequest : AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.bucket = Constants.Strings.S3BucketThumbnails
        downloadRequest.key =  imageKey
        downloadRequest.downloadingFileURL = downloadingFileURL
        
        transferManager?.download(downloadRequest).continue({ (task) -> AnyObject! in
            if let error = task.error {
                if error._domain == AWSS3TransferManagerErrorDomain as String
                    && AWSS3TransferManagerErrorType(rawValue: error._code) == AWSS3TransferManagerErrorType.paused {
                    print("AVC: DOWNLOAD PAUSED")
                } else {
                    print("AVC: DOWNLOAD FAILED: [\(error)]")
                }
            } else if let exception = task.exception {
                print("AVC: DOWNLOAD FAILED: [\(exception)]")
            } else {
                print("AVC: DOWNLOAD SUCCEEDED")
                DispatchQueue.main.async(execute: { () -> Void in
                    // Assign the image to the Preview Image View
                    if FileManager().fileExists(atPath: downloadingFilePath) {
                        print("IMAGE FILE AVAILABLE")
                        let thumbnailData = try? Data(contentsOf: URL(fileURLWithPath: downloadingFilePath))
                        
                        // Ensure the Thumbnail Data is not null
                        if let tData = thumbnailData {
                            print("GET IMAGE - CHECK 1")
                            
                            // Find the correct User Object in the global list and assign the newly downloaded Image
                            loopUserObjectCheck: for blobObject in self.userBlobs {
                                if blobObject.blobID == blobID {
                                    blobObject.blobThumbnail = UIImage(data: tData)
                                    
                                    break loopUserObjectCheck
                                }
                            }
                            
                            print("ADDED IMAGE: \(imageKey))")
                            
                            // Reload the Table View
                            print("GET IMAGE - RELOAD TABLE VIEW")
                            self.blobsUserTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
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
