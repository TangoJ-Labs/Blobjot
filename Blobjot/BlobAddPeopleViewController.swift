//
//  BlobAddPeopleViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 7/31/16.
//  Copyright © 2016 tangojlabs. All rights reserved.
//

import AWSLambda
import AWSS3
import UIKit


// Create a protocol with functions declared in other View Controllers implementing this protocol (delegate)
protocol BlobAddPeopleViewControllerDelegate {
    
    // When called, the parent View Controller changes the type of Blob to add
    func changeMapCircleType(type: Constants.BlobTypes)
}

class BlobAddPeopleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    // Add a delegate variable which the parent view controller can pass its own delegate instance to and have access to the protocol
    // (and have its own functions called that are listed in the protocol)
    var blobAddPeopleDelegate: BlobAddPeopleViewControllerDelegate?
    
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    // Declare the view components
    var viewContainer: UIView!
    var searchBarContainer: UIView!
    var selectAllContainer: UIView!
    var selectAllLabel: UILabel!
    var selectAllBox: UILabel!
    var searchBar: UISearchBar!
    var peopleTableViewActivityIndicator: UIActivityIndicatorView!
    var peopleTableView: UITableView!
//    var peopleViewContainer: UIView!
    var selectAllMessage: UITextView!
    
    var selectAllTapGesture: UITapGestureRecognizer!
    
    var selectAll: Bool = false
    var peopleList = [User]()
    var peopleListSelected = [User]()
    var peopleListUse = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Status Bar Settings
        statusBarHeight = UIApplication.sharedApplication().statusBarFrame.size.height
        print("**************** BAPVC STATUS BAR HEIGHT: \(statusBarHeight)")
        viewFrameY = self.view.frame.minY
        print("**************** BAPVC VIEW FRAME Y: \(viewFrameY)")
        screenSize = UIScreen.mainScreen().bounds
        print("**************** BAPVC SCREEN HEIGHT: \(screenSize.height)")
        print("**************** BAPVC VIEW HEIGHT: \(self.view.frame.height)")
        
        // Add the view container to hold all other views (decrease size to match pageViewController)
        viewContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height - 74 - self.view.frame.width))
        self.view.addSubview(viewContainer)
        
        searchBarContainer = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: Constants.Dim.blobAddPeopleSearchBarHeight))
        searchBarContainer.backgroundColor = Constants.Colors.colorBlobAddPeopleSearchBar
        viewContainer.addSubview(searchBarContainer)
        
        let selectAllWidth: CGFloat = 100
        let selectBoxSize: CGFloat = 20
        selectAllContainer = UIView(frame: CGRect(x: searchBarContainer.frame.width - selectAllWidth, y: 0, width: selectAllWidth, height: searchBarContainer.frame.height))
        searchBarContainer.addSubview(selectAllContainer)
        
        selectAllLabel = UILabel(frame: CGRect(x: 5, y: 0, width: selectAllWidth - 15 - selectBoxSize, height: selectAllContainer.frame.height))
        selectAllLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 14)
        selectAllLabel.text = "Select All:"
        selectAllLabel.textAlignment = .Left
        selectAllLabel.textColor = UIColor.whiteColor()
        selectAllContainer.addSubview(selectAllLabel)
        
        selectAllBox = UILabel(frame: CGRect(x: selectAllWidth - 5 - selectBoxSize, y: (selectAllContainer.frame.height - selectBoxSize) / 2, width: selectBoxSize, height: selectBoxSize))
        selectAllBox.layer.borderColor = UIColor.whiteColor().CGColor
        selectAllBox.layer.borderWidth = 1
        selectAllBox.font = UIFont(name: Constants.Strings.fontRegular, size: 18)
        selectAllBox.text = ""
        selectAllBox.textAlignment = .Center
        selectAllBox.textColor = UIColor.whiteColor()
        selectAllContainer.addSubview(selectAllBox)
        
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: searchBarContainer.frame.width - selectAllWidth, height: searchBarContainer.frame.height))
        searchBar.delegate = self
        searchBar.barStyle = .Default
        searchBar.backgroundImage = getImageWithColor(Constants.Colors.colorBlobAddPeopleSearchBar, size: CGSize(width: 5, height: 5))
        searchBar.tintColor = Constants.Colors.colorBlobAddPeopleSearchBar
        searchBarContainer.addSubview(searchBar)
        
        // Add a loading indicator while downloading the logged in user image
        peopleTableViewActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: searchBarContainer.frame.height, width: viewContainer.frame.width, height: Constants.Dim.blobAddPeopleTableViewCellHeight))
        peopleTableViewActivityIndicator.color = UIColor.blackColor()
        viewContainer.addSubview(peopleTableViewActivityIndicator)
        peopleTableViewActivityIndicator.startAnimating()
        
        peopleTableView = UITableView(frame: CGRect(x: 0, y: searchBar.frame.height, width: viewContainer.frame.width, height: viewContainer.frame.height - searchBar.frame.height))
        peopleTableView.dataSource = self
        peopleTableView.delegate = self
        peopleTableView.registerClass(BlobAddPeopleTableViewCell.self, forCellReuseIdentifier: Constants.Strings.blobAddPeopleTableViewCellReuseIdentifier)
        peopleTableView.separatorStyle = .None
        peopleTableView.allowsMultipleSelection = true
        peopleTableView.backgroundColor = UIColor.clearColor()
        peopleTableView.alwaysBounceVertical = true
        peopleTableView.showsVerticalScrollIndicator = false
        viewContainer.addSubview(peopleTableView)
        
//        peopleViewContainer = UIView(frame: CGRect(x: 0, y: searchBar.frame.height, width: viewContainer.frame.width, height: viewContainer.frame.height - searchBar.frame.height))
//        peopleViewContainer.backgroundColor = UIColor.redColor()
//        viewContainer.addSubview(peopleViewContainer)
//        
//        let peopleViewController = PeopleViewController()
//        peopleViewController.loadConnectionsOnly = true
//        peopleViewController.useBarHeights = false
//        peopleViewController.printCheck = "CHILD"
//        addChildViewController(peopleViewController)
//        print("BAP - PEOPLE VIEW CONTAINER: \(peopleViewContainer.frame)")
//        peopleViewController.view.frame = CGRect(x: 0, y: 0, width: peopleViewContainer.frame.width, height: peopleViewContainer.frame.height)
//        peopleViewContainer.addSubview(peopleViewController.view)
//        peopleViewController.didMoveToParentViewController(self)
        
        selectAllMessage = UITextView(frame: CGRect(x: 0, y: searchBar.frame.height, width: viewContainer.frame.width, height: viewContainer.frame.height - searchBar.frame.height))
        selectAllMessage.backgroundColor = Constants.Colors.colorBlobAddPeopleSearchBar
        selectAllMessage.editable = false
        selectAllMessage.scrollEnabled = false
        selectAllMessage.font = UIFont(name: Constants.Strings.fontRegular, size: 26)
        selectAllMessage.text = "Visible to\nall connections."
        selectAllMessage.textAlignment = .Center
        selectAllMessage.textColor = UIColor.whiteColor()
        
        selectAllTapGesture = UITapGestureRecognizer(target: self, action: #selector(BlobAddPeopleViewController.tapSelectAll(_:)))
        selectAllTapGesture.numberOfTapsRequired = 1  // add single tap
        selectAllContainer.addGestureRecognizer(selectAllTapGesture)
        
        getUserConnections()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return peopleListUse.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return Constants.Dim.blobAddPeopleTableViewCellHeight
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Strings.blobAddPeopleTableViewCellReuseIdentifier, forIndexPath: indexPath) as! BlobAddPeopleTableViewCell
        print("CELL \(indexPath.row): \(cell)")
        
        cell.cellUserImageActivityIndicator.startAnimating()
        
        // Add a clear background for the selectedBackgroundView so that the row is not highlighted when selected
        let sbv = UIView(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height))
        sbv.backgroundColor = Constants.Colors.colorPurple
        cell.selectedBackgroundView = sbv
        
        let cellUserObject = self.peopleListUse[indexPath.row]
        print("USER NAME: \(cellUserObject.userName) FOR CELL: \(indexPath.row)")
        
        // Get the User Object from the list and assign data to the cell
        cell.cellUserName.text = cellUserObject.userName
        if let cellUserImage = cellUserObject.userImage {
            cell.cellUserImage.image = cellUserImage
            
            cell.cellUserImageActivityIndicator.stopAnimating()
        } else {
            self.getUserImage(cellUserObject.userID, imageKey: cellUserObject.userImageKey)
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("DID SELECT ROW: \(indexPath.row)")
        
        // Add the selected person to the selected list if they do not already exist
        var personExists = false
        loopPeopleListSelected: for person in peopleListSelected {
            if person.userID == peopleListUse[indexPath.row].userID {
                personExists = true
                break loopPeopleListSelected
            }
        }
        if !personExists {
            peopleListSelected.append(peopleListUse[indexPath.row])
        }
        
        // SELECTED PEOPLE CHECK
        for person in peopleListSelected {
            print("PERSON SELECTED: \(person.userName)")
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        print("DID DESELECT ROW: \(indexPath.row)")
        
        loopPeopleListSelected: for (index, person) in peopleListSelected.enumerate() {
            if person.userID == peopleListUse[indexPath.row].userID {
                peopleListSelected.removeAtIndex(index)
                break loopPeopleListSelected
            }
        }
        
        // SELECTED PEOPLE CHECK
        for person in peopleListSelected {
            print("PERSON SELECTED: \(person.userName)")
        }
    }
    
    func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        print("DID HIGHLIGHT ROW: \(indexPath.row)")
    }
    
    func tableView(tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath) {
        print("DID UNHIGHLIGHT ROW: \(indexPath.row)")
    }
    
    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    
    // MARK:  UISearchBarDelegate protocol
    
    // Edit the peopleList based on the search text filter
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        print("Search Text: \(searchText)")
        
        // If the search bar is cleared, clear the peopleList and add all users
        self.peopleListUse = [User]()
        if searchText == "" {
            for addPerson in self.peopleList {
                self.peopleListUse.append(addPerson)
            }
            
            // else filter the list by clearing the peopleList and appending only the matching Users
        } else {
            for userObject in self.peopleList {
                // Convert the strings to lowercase for better matching
                if userObject.userName.lowercaseString.containsString(searchText.lowercaseString) {
                    print("UserName Contains: \(searchText)")
                    
                    self.peopleListUse.append(userObject)
                }
            }
        }
        
        // Reload the Table View
        print("BAP - SEARCH BAR - RELOAD TABLE VIEW")
        self.peopleTableView.performSelectorOnMainThread(#selector(UITableView.reloadData), withObject: nil, waitUntilDone: true)
        
        // Loop through the Selected People list and highlight the associated people in the Use People list
        for selectedPerson in peopleListSelected {
            loopUsePeopleList: for (useIndex, usePerson) in self.peopleListUse.enumerate() {
                if usePerson.userID == selectedPerson.userID {
                    
                    // Highlight that person in the table view
                    self.peopleTableView.selectRowAtIndexPath(NSIndexPath(forRow: useIndex, inSection: 0), animated: false, scrollPosition: UITableViewScrollPosition.None)
                    break loopUsePeopleList
                }
            }
        }
    }
    
    
    // MARK: GESTURE METHODS
    
    func tapSelectAll(gesture: UIGestureRecognizer) {
        if selectAll {
            selectAll = false
            selectAllBox.text = ""
            selectAllMessage.removeFromSuperview()
            searchBarContainer.addSubview(searchBar)
            
            if let parentVC = self.blobAddPeopleDelegate {
                parentVC.changeMapCircleType(Constants.BlobTypes.Temporary)
            }
            
        } else {
            selectAll = true
            selectAllBox.text = "\u{2713}"
            viewContainer.addSubview(selectAllMessage)
            searchBar.removeFromSuperview()
            
            if let parentVC = self.blobAddPeopleDelegate {
                parentVC.changeMapCircleType(Constants.BlobTypes.Public)
            }
        }
    }
    
    
    // MARK: CUSTOM FUNCTIONS
    
    // Create a solid color UIImage
    func getImageWithColor(color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRectMake(0, 0, size.width, size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    
    // MARK: AWS FUNCTIONS
    
    // The initial request for Map Blob data - called when the View Controller is instantiated
    func getUserConnections() {
        print("BAP - REQUESTING GUC")
        
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["user_id" : Constants.Data.currentUser, "print_check" : "BAP"]
        
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        lambdaInvoker.invokeFunction("Blobjot-GetUserConnections", JSONObject: json, completionHandler: { (response, err) -> Void in
            
            if (err != nil) {
                print("BAP - GET USER CONNECTIONS DATA ERROR: \(err)")
            } else if (response != nil) {
                
                // Convert the response to an array of arrays
                if let userConnectionArrays = response as? [[AnyObject]] {
                    
                    // Loop through the arrays and add each user - the arrays should be in the proper order by user type
                    for (arrayIndex, userArray) in userConnectionArrays.enumerate() {
                        print("PVC-GUC: array: \(arrayIndex): jsonData: \(userArray)")
                        print("BAP - USER COUNT: \(userArray.count)")
                        
                        // Stop the table loading spinner before adding data so that it does not show up in front of the user list
                        //                        self.accountTableActivityIndicator.stopAnimating()
                        
                        // Loop through each AnyObject (User) in the array
                        for user in userArray {
                            print("BAP - USER: \(user)")
                            
                            // Convert the AnyObject to JSON with keys and AnyObject values
                            // Then convert the AnyObject values to Strings or Numbers depending on their key
                            if let checkUser = user as? [String: AnyObject] {
                                let userID = checkUser["user_id"] as! String
                                let userName = checkUser["user_name"] as! String
                                let userImageKey = checkUser["user_image_key"] as! String
                                print("BAP - USER ID: \(userID)")
                                print("BAP - USER NAME: \(userName)")
                                print("BAP - USER IMAGE KEY: \(userImageKey)")
                                
                                // Create a User Object and add it to the global User array
                                let addUser = User()
                                addUser.userID = userID
                                addUser.userName = userName
                                addUser.userImageKey = userImageKey
                                addUser.userStatus = Constants.UserStatusTypes(rawValue: arrayIndex)
                                
                                print("BAP - TRYING TO ADD DOWNLOADED USER: \(userName)")
                                
                                // Check to ensure the user does not already exist in the local User array
                                var personExists = false
                                loopPersonCheck: for personObject in self.peopleList {
                                    if personObject.userID == userID {
                                        personObject.userName = userName
                                        personObject.userImageKey = userImageKey
                                        personObject.userStatus = Constants.UserStatusTypes(rawValue: arrayIndex)
                                        
                                        personExists = true
                                        break loopPersonCheck
                                    }
                                }
                                if personExists == false {
                                    
                                    // Add the User Object to the local list if they are a connection
                                    if addUser.userStatus == Constants.UserStatusTypes.Connected {
                                        self.peopleList.append(addUser)
                                        print("BAP - ADDED CONNECTED USER \(addUser.userName) TO PEOPLE LIST")
                                    }
                                }
                                print("BAP - PEOPLE LIST COUNT: \(self.peopleList.count)")
                            }
                        }
                    }
                    
                    // Sort the list alphabetically and copy the peopleList to the peopleList to use in the table
                    self.peopleList.sortInPlace({$0.userName <  $1.userName})
                    self.peopleListUse = self.peopleList
                    
                    // Reload the Table View
                    print("BAP - GET DATA - RELOAD TABLE VIEW")
                    self.peopleTableView.performSelectorOnMainThread(#selector(UITableView.reloadData), withObject: nil, waitUntilDone: true)
                }
            }
        })
    }
    
    // Download User Image
    func getUserImage(userID: String, imageKey: String) {
        print("BAP - GETTING IMAGE FOR: \(imageKey)")
        
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
                    print("BAP - DOWNLOAD PAUSED")
                } else {
                    print("BAP - DOWNLOAD FAILED: [\(error)]")
                }
            } else if let exception = task.exception {
                print("BAP - DOWNLOAD FAILED: [\(exception)]")
            } else {
                print("BAP - DOWNLOAD SUCCEEDED")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    // Assign the image to the Preview Image View
                    if NSFileManager().fileExistsAtPath(downloadingFilePath) {
                        print("BAP - IMAGE FILE AVAILABLE")
                        let thumbnailData = NSData(contentsOfFile: downloadingFilePath)
                        
                        // Ensure the Thumbnail Data is not null
                        if let tData = thumbnailData {
                            print("BAP - GET IMAGE - CHECK 1")
                            
                            // Find the correct User Object in the local list and assign the newly downloaded Image
                            loopUserObjectCheckLocal: for userObjectLocal in self.peopleList {
                                if userObjectLocal.userID == userID {
                                    userObjectLocal.userImage = UIImage(data: tData)
                                    
                                    break loopUserObjectCheckLocal
                                }
                            }
                            
                            print("ADDED IMAGE: \(imageKey))")
                            
                            // Reload the Table View
                            print("BAP - GET IMAGE - RELOAD TABLE VIEW")
                            self.peopleTableView.performSelectorOnMainThread(#selector(UITableView.reloadData), withObject: nil, waitUntilDone: true)
                        }
                        
                    } else {
                        print("BAP - FRAME FILE NOT AVAILABLE")
                    }
                })
            }
            return nil
        })
    }

}
