//
//  PeopleViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 8/1/16.
//  Copyright © 2016 tangojlabs. All rights reserved.
//

import AWSLambda
import AWSS3
import UIKit

// Create a protocol with functions declared in other View Controllers implementing this protocol (delegate)
protocol PeopleViewControllerDelegate {
    
    // When called, the parent View Controller is alerted that the global User Object list has been updated
    func userObjectListUpdatedWithCurrentUser()
}

class PeopleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate {

    // Add a delegate variable which the parent view controller can pass its own delegate instance to and have access to the protocol
    // (and have its own functions called that are listed in the protocol)
    var peopleViewDelegate: PeopleViewControllerDelegate?
    
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    var viewContainer: UIView!
    var searchBarContainer: UIView!
    var searchBar: UISearchBar!
    var searchExitView: UIView!
    var searchExitLabel: UILabel!
    var peopleTableViewActivityIndicator: UIActivityIndicatorView!
    var peopleTableView: UITableView!
    lazy var refreshControl: UIRefreshControl = UIRefreshControl()
    var refreshView: UIView!
    
    var cellPeopleTableViewTapGesture: UITapGestureRecognizer!
    var searchExitTapGesture: UITapGestureRecognizer!
    
    var useBarHeights = true
    var peopleListTopPerson: String!
    var peopleList = [User]()
    var selectedPeopleList = [User]()
    
    var printCheck = ""
    
    override func viewWillLayoutSubviews() {
        print("PVC - \(self.printCheck) - VIEW WILL LAYOUT SUBVIEWS")
        
        // Status Bar Settings
        UIApplication.sharedApplication().statusBarHidden = false
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        statusBarHeight = UIApplication.sharedApplication().statusBarFrame.size.height
        navBarHeight = self.navigationController?.navigationBar.frame.height
        print("**************** PVC - \(self.printCheck) - NAV BAR HEIGHT: \(navBarHeight)")
        viewFrameY = self.view.frame.minY
        print("**************** PVC - \(self.printCheck) - VIEW FRAME Y: \(viewFrameY)")
        screenSize = UIScreen.mainScreen().bounds
        print("**************** PVC - \(self.printCheck) - SCREEN HEIGHT: \(screenSize.height)")
        print("**************** PVC - \(self.printCheck) - VIEW HEIGHT: \(self.view.frame.height)")
        
        if !useBarHeights {
            statusBarHeight = 0
            navBarHeight = 0
        }
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: statusBarHeight + navBarHeight, width: self.view.frame.width, height: self.view.frame.height - statusBarHeight - navBarHeight))
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        self.view.addSubview(viewContainer)
        
        searchBarContainer = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width - Constants.Dim.peopleSearchBarHeight, height: Constants.Dim.peopleSearchBarHeight))
        searchBarContainer.backgroundColor = Constants.Colors.colorPeopleSearchBar
        viewContainer.addSubview(searchBarContainer)
        
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: searchBarContainer.frame.width, height: searchBarContainer.frame.height))
        searchBar.delegate = self
        searchBar.barStyle = .Default
        searchBar.backgroundImage = getImageWithColor(Constants.Colors.colorStatusBar, size: CGSize(width: 5, height: 5))
        searchBar.tintColor = Constants.Colors.colorStatusBar
        searchBarContainer.addSubview(searchBar)
        
//        for view in searchBar.subviews {
//            for subview in view.subviews {
//                if subview .isKindOfClass(UITextField) {
//                    let textField: UITextField = subview as! UITextField
//                    textField.backgroundColor = UIColor.redColor()
//                }
//            }
//        }
        
        // Add the Search Exit Button to close the keyboard
        searchExitView = UIView(frame: CGRect(x: searchBarContainer.frame.width, y: 0, width: Constants.Dim.peopleSearchBarHeight, height: Constants.Dim.peopleSearchBarHeight))
        searchExitView.backgroundColor = Constants.Colors.colorStatusBar
        viewContainer.addSubview(searchExitView)
        
        searchExitLabel = UILabel(frame: CGRect(x: 5, y: 5, width: Constants.Dim.peopleSearchBarHeight - 10, height: Constants.Dim.peopleSearchBarHeight - 10))
        searchExitLabel.backgroundColor = UIColor.clearColor()
        searchExitLabel.text = "\u{2573}"
        searchExitLabel.textAlignment = .Center
        searchExitLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
        searchExitLabel.textColor = UIColor.whiteColor()
        searchExitView.addSubview(searchExitLabel)
        
//        // Add a loading indicator while downloading the logged in user image
//        peopleTableViewActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: searchBarContainer.frame.height, width: viewContainer.frame.width, height: Constants.Dim.peopleTableViewCellHeight))
//        peopleTableViewActivityIndicator.color = UIColor.blackColor()
//        viewContainer.addSubview(peopleTableViewActivityIndicator)
//        peopleTableViewActivityIndicator.startAnimating()
        
        peopleTableView = UITableView(frame: CGRect(x: 0, y: searchBarContainer.frame.height, width: viewContainer.frame.width, height: viewContainer.frame.height - searchBarContainer.frame.height))
        peopleTableView.dataSource = self
        peopleTableView.delegate = self
        peopleTableView.registerClass(PeopleTableViewCell.self, forCellReuseIdentifier: Constants.Strings.peopleTableViewCellReuseIdentifier)
        peopleTableView.separatorStyle = .None
        peopleTableView.backgroundColor = UIColor.clearColor()
        peopleTableView.allowsSelection = true
        peopleTableView.alwaysBounceVertical = true
        peopleTableView.showsVerticalScrollIndicator = false
        viewContainer.addSubview(peopleTableView)
        
        // Create a refresh control for the CollectionView and add a subview to move the refresh control where needed
//        refreshView = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: 40))
//        peopleTableView.addSubview(refreshView)
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "")
        refreshControl.addTarget(self, action: #selector(PeopleViewController.refreshDataManually), forControlEvents: UIControlEvents.ValueChanged)
        peopleTableView.addSubview(refreshControl)
        peopleTableView.contentOffset = CGPointMake(0, -self.refreshControl.frame.size.height)
        refreshControl.beginRefreshing()
        
        cellPeopleTableViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(PeopleViewController.tapPeopleTableView(_:)))
        cellPeopleTableViewTapGesture.numberOfTapsRequired = 1  // add single tap
        peopleTableView.addGestureRecognizer(cellPeopleTableViewTapGesture)
        
        searchExitTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapSearchExit(_:)))
        searchExitTapGesture.numberOfTapsRequired = 1  // add single tap
        searchExitView.addGestureRecognizer(searchExitTapGesture)
        
        getUserConnections()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("PVC - \(self.printCheck) - VIEW DID LOAD")
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
        print("PVC - \(self.printCheck) - PEOPLE LIST COUNT: \(self.peopleList.count)")
        return self.peopleList.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return Constants.Dim.accountTableViewCellHeight
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Strings.peopleTableViewCellReuseIdentifier, forIndexPath: indexPath) as! PeopleTableViewCell
        print("CELL \(indexPath.row): \(cell)")
        
        cell.cellUserName.text = ""
        cell.cellUserImage.image = nil
        cell.cellConnectStar.image = UIImage(named: Constants.Strings.imageStringStarEmpty)
        cell.cellActionMessage.text = ""
        cell.cellUserImageActivityIndicator.startAnimating()
        
        // Add a clear background for the selectedBackgroundView so that the row is not highlighted when selected
        let sbv = UIView(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height))
        sbv.backgroundColor = UIColor.clearColor()
        cell.selectedBackgroundView = sbv
        
        let cellUserObject = self.peopleList[indexPath.row]
        print("USER NAME: \(cellUserObject.userName) FOR CELL: \(indexPath.row)")
        
        // Get the User Object from the list and assign data to the cell
        cell.cellUserName.text = cellUserObject.userName
        if let cellUserImage = cellUserObject.userImage {
            cell.cellUserImage.image = cellUserImage
            
            cell.cellUserImageActivityIndicator.stopAnimating()
        } else {
            self.getUserImage(cellUserObject.userID, imageKey: cellUserObject.userImageKey)
        }
        
        print("USER STATUS: \(cellUserObject.userStatus)")
        if cellUserObject.userStatus == Constants.UserStatusTypes.Pending {
            cell.cellConnectStar.image = UIImage(named: Constants.Strings.imageStringStarHalfFilled)
            cell.cellActionMessage.text = "Pending Request..."
        } else if cellUserObject.userStatus == Constants.UserStatusTypes.Waiting {
            cell.cellConnectStar.image = UIImage(named: Constants.Strings.imageStringStarHalfFilled)
            cell.cellActionMessage.text = "Waiting for Response..."
        } else if cellUserObject.userStatus == Constants.UserStatusTypes.Connected {
            cell.cellConnectStar.image = UIImage(named: Constants.Strings.imageStringStarFilled)
            cell.cellActionMessage.text = ""
        } else if cellUserObject.userStatus == Constants.UserStatusTypes.Blocked {
            cell.cellConnectStar.image = UIImage(named: Constants.Strings.imageStringStarEmpty)
            cell.cellActionMessage.text = "User Blocked"
        } else {
            cell.cellConnectStar.image = UIImage(named: Constants.Strings.imageStringStarEmpty)
            cell.cellActionMessage.text = ""
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("DID SELECT ROW: \(indexPath.row)")
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        print("DID DESELECT ROW: \(indexPath.row)")
    }
    
    func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        print("DID HIGHLIGHT ROW: \(indexPath.row)")
    }
    
    func tableView(tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath) {
        print("DID UNHIGHLIGHT ROW: \(indexPath.row)")
    }
    
    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
//        editingStyle = UITableViewCellEditingStyle.Delete
    }
    
    // Return the action types for the row slide options
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        // Set the default return action
        let add = UITableViewRowAction(style: .Normal, title: "Connect") { action, index in
            print("add connection button tapped")
            
            // Call to change the userStatus to 3 (NotConnected) and prepare the view
            self.updateUserStatusType(self.peopleList[indexPath.row].userID, peopleListIndex: indexPath.row, userStatus: Constants.UserStatusTypes.Waiting)
        }
        add.backgroundColor = UIColor.yellowColor()
        var returnActions = [add]
        
        // Check the user status type based on the index of the peopleList array (see the list in the User class)
        let rowUser = self.peopleList[indexPath.row]
        print("IN ROW ACTIONS FOR ROW: \(indexPath.row) AND USER: \(rowUser.userName)")
        
        if rowUser.userStatus == Constants.UserStatusTypes.Pending {
            // PENDING USERS
            print("IN PENDING USER ACTIONS")
            let block = UITableViewRowAction(style: .Normal, title: "Block\nUser") { action, index in
                print("block button tapped")
                // Remove the person from the global people list
                loopUserObjectCheck: for (userIndex, userObject) in Constants.Data.userObjects.enumerate() {
                    if userObject.userID == self.peopleList[indexPath.row].userID {
                        Constants.Data.userObjects.removeAtIndex(userIndex)
                        
                        break loopUserObjectCheck
                    }
                }
                // Call to change the userStatus to 3 (NotConnected) and prepare the view
                self.updateUserStatusType(self.peopleList[indexPath.row].userID, peopleListIndex: indexPath.row, userStatus: Constants.UserStatusTypes.Blocked)
            }
            block.backgroundColor = UIColor.blackColor()
            
            let delete = UITableViewRowAction(style: .Normal, title: "Delete\nRequest") { action, index in
                print("delete request button tapped")
                
                // Call to change the userStatus to 3 (NotConnected) and prepare the view
                self.updateUserStatusType(self.peopleList[indexPath.row].userID, peopleListIndex: indexPath.row, userStatus: Constants.UserStatusTypes.NotConnected)
            }
            delete.backgroundColor = UIColor.redColor()
            
            let add = UITableViewRowAction(style: .Normal, title: "Connect") { action, index in
                print("add connection button tapped")
                
                // Call to change the userStatus to 3 (NotConnected) and prepare the view
                self.updateUserStatusType(self.peopleList[indexPath.row].userID, peopleListIndex: indexPath.row, userStatus: Constants.UserStatusTypes.Connected)
            }
            add.backgroundColor = UIColor.yellowColor()
            
            returnActions = [add, delete, block]
            
        } else if rowUser.userStatus == Constants.UserStatusTypes.Waiting {
            // WAITING USERS
            print("IN WAITING USER ACTIONS")
            let delete = UITableViewRowAction(style: .Normal, title: "Delete\nRequest") { action, index in
                print("delete request button tapped")
                
                // Call to change the userStatus to 3 (NotConnected) and prepare the view
                self.updateUserStatusType(self.peopleList[indexPath.row].userID, peopleListIndex: indexPath.row, userStatus: Constants.UserStatusTypes.NotConnected)
            }
            delete.backgroundColor = UIColor.redColor()
            
            returnActions = [delete]
            
        } else if rowUser.userStatus == Constants.UserStatusTypes.Connected {
            // CONNECTED USERS
            print("IN CONNECTED USER ACTIONS")
            let delete = UITableViewRowAction(style: .Normal, title: "Delete\nConnection") { action, index in
                print("delete connection button tapped")
                
                // Call to change the userStatus to 3 (NotConnected) and prepare the view
                self.updateUserStatusType(self.peopleList[indexPath.row].userID, peopleListIndex: indexPath.row, userStatus: Constants.UserStatusTypes.NotConnected)
            }
            delete.backgroundColor = UIColor.redColor()
            
            returnActions = [delete]
        } else if rowUser.userStatus == Constants.UserStatusTypes.Blocked {
            // CONNECTED USERS
            print("IN BLOCKED USER ACTIONS")
            let delete = UITableViewRowAction(style: .Normal, title: "Unblock\nUser") { action, index in
                print("unblock user button tapped")
                
                // Call to change the userStatus to 3 (NotConnected) and prepare the view
                self.updateUserStatusType(self.peopleList[indexPath.row].userID, peopleListIndex: indexPath.row, userStatus: Constants.UserStatusTypes.NotConnected)
            }
            delete.backgroundColor = UIColor.redColor()
            
            returnActions = [delete]
        }
        
        print("RETURNING ROW ACTIONS")
        return returnActions
    }
    
    // The user swiped down on the Table View - delete all data and re-download
    func refreshDataManually(sender: AnyObject) {
        print("PVC - MANUALLY REFRESH TABLE")
        // Clear the current peopleList and any selections
        self.peopleList = [User]()
        self.selectedPeopleList = [User]()
        
        // Clear the Table View
        self.refreshTableViewAndEndSpinner(false)
        
        // Recall the data
        self.getUserConnections()
    }
    
    
    // MARK:  UISearchBarDelegate protocol
    
    // Edit the peopleList based on the search text filter
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        print("Search Text: \(searchText)")
        
        // If the search bar is cleared, clear the peopleList and add all but the currently logged in user
        self.peopleList = [User]()
        if searchText == "" {
            for addPerson in Constants.Data.userObjects {
                
                // Ensure the person is not the currently logged in user
                if addPerson.userID != Constants.Data.currentUser {
                    self.peopleList.append(addPerson)
                }
            }
            
            // else filter the list by clearing the peopleList and appending only the matching Users
        } else {
            self.peopleList = [User]()
            
            for userObject in Constants.Data.userObjects {
                // Convert the strings to lowercase for better matching
                if userObject.userName.lowercaseString.containsString(searchText.lowercaseString) {
                    print("UserName Contains: \(searchText)")
                    
                    // Ensure the person is not the currently logged in user
                    if userObject.userID != Constants.Data.currentUser {
                        self.peopleList.append(userObject)
                    }
                }
            }
        }
        self.refreshTableViewAndEndSpinner(true)
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        print("UPDATE SEARCH RESULTS FOR SEARCH CONTROLLER: \(searchController)")
    }
    
    
    // MARK: GESTURE METHODS
    
    func tapSearchExit(gesture: UITapGestureRecognizer) {
        searchBar.resignFirstResponder()
    }
    
    func tapPeopleTableView(gesture: UITapGestureRecognizer) {
        let tapPoint = gesture.locationInView(peopleTableView)
        print("TAP POINT: \(tapPoint)")
        let iPath = peopleTableView.indexPathForRowAtPoint(tapPoint)
        
        if let indexPath = iPath {
            let cell = peopleTableView.dequeueReusableCellWithIdentifier(Constants.Strings.peopleTableViewCellReuseIdentifier, forIndexPath: indexPath) as! PeopleTableViewCell
            print("CELL \(indexPath.row): \(cell)")
            
            let pointInCell = gesture.locationInView(cell.cellContainer)
            print("CELL STAR FRAME: \(cell.cellConnectStar.frame)")
            print("POINT IN CELL: \(pointInCell.x), \(pointInCell.y)")
            if CGRectContainsPoint(cell.cellConnectStar.frame, pointInCell) {
                print("TOUCH IN STAR")
                
                // Check the user status type based on the index of the peopleList array (see the list in the User class)
                let rowUser = self.peopleList[indexPath.row]
                print("IN ROW ACTIONS FOR ROW: \(indexPath.row) AND USER: \(rowUser.userName)")
                
                // Set default userStatus settings
                var userStatus = Constants.UserStatusTypes.Waiting
                
                if rowUser.userStatus == Constants.UserStatusTypes.Pending {
                    // PENDING USERS
                    print("TAPPED PENDING USER STAR")
                    // Change the userStatus to 3 (Other) and set the actionType to delete
                    userStatus = Constants.UserStatusTypes.Connected
                    
                } else if rowUser.userStatus == Constants.UserStatusTypes.Waiting || rowUser.userStatus == Constants.UserStatusTypes.Connected || rowUser.userStatus == Constants.UserStatusTypes.Blocked {
                    // WAITING, CONNECTED, OR BLOCKED USERS
                    print("TAPPED WAITING, CONNECTED, OR BLOCKED USER STAR")
                    // Change the userStatus to 3 (Other) and set the actionType to delete
                    userStatus = Constants.UserStatusTypes.NotConnected
                    
                } else {
                    // NOT CONNECTED USERS - will keep default "Waiting" status type set above
                    print("TAPPED NOT CONNECTED USER STAR")
                }
                
                updateUserStatusType(self.peopleList[indexPath.row].userID, peopleListIndex: indexPath.row, userStatus: userStatus)
                
            } else if CGRectContainsPoint(cell.cellUserImage.frame, pointInCell) {
                print("TOUCH IN USER IMAGE")
// *COMPLETE*********FIX REFERENCE TO USER ID FROM USER OBJECT ITEM
//                loadPeopleViewControllerWithTopUser(peopleList[indexPath!.row])
            }
            
            print("PEOPLE TABLE VIEW: RELOADING TABLE VIEW")
            // Reload the Table View
            self.refreshTableViewAndEndSpinner(false)
            
// *COMPLETE******** ADD UPLOAD & DATA METHODS TO UPDATE CONNECTED USERS

        }
    }
    
    
    // MARK: CUSTOM FUNCTIONS
    
    func popViewController(sender: UIBarButtonItem) {
        print("pop Back to Account View")
        self.dismissViewControllerAnimated(true, completion: {
        })
    }
    
    func updateUserStatusType(counterpartUserID: String, peopleListIndex: Int, userStatus: Constants.UserStatusTypes) {
        // Update the associated user's userStatus locally and refresh the Table View
        self.peopleList[peopleListIndex].userStatus = userStatus
        self.refreshTableViewAndEndSpinner(true)
        
        // Update the associated user's userStatus globally
        loopUserObjectUpdate: for userObject in Constants.Data.userObjects {
            if userObject.userID == counterpartUserID {
                userObject.userStatus = userStatus
                
                break loopUserObjectUpdate
            }
        }
        
        var actionType = "connect"
        if userStatus == Constants.UserStatusTypes.NotConnected {
            actionType = "delete"
        } else if userStatus == Constants.UserStatusTypes.Blocked {
            actionType = "block"
        }
        
        // Add a user connection action in AWS
        self.addUserConnectionAction(Constants.Data.currentUser, connectionUserID: counterpartUserID, actionType: actionType)
    }
    
    func refreshTableViewAndEndSpinner(endSpinner: Bool) {
        // Sort the list in case the userStatuses were changed
//        self.peopleList.sortInPlace({$0.userStatus.rawValue <  $1.userStatus.rawValue})
        
        // Reload the Table View
        print("GET DATA - RELOAD TABLE VIEW")
        self.peopleTableView.performSelectorOnMainThread(#selector(UITableView.reloadData), withObject: nil, waitUntilDone: true)
        
        if endSpinner {
            print("RELOAD TABLE VIEW - END REFRESHING")
            self.refreshControl.endRefreshing()
//            self.peopleTableViewActivityIndicator.stopAnimating()
//            self.peopleTableViewActivityIndicator.removeFromSuperview()
        }
    }
    
    func bringTopPersonToFrontOfPeopleList() {
        
        // Ensure that the person was assigned
        if self.peopleListTopPerson != nil {
            // In the peopleList, find the person indicated to be at the top of the list
            // and move them to the beginning of the list.  Be sure to remove them from their current position.
            for (index, person) in peopleList.enumerate() {
                if person.userID == self.peopleListTopPerson {
                    peopleList.removeAtIndex(index)
                    peopleList.insert(person, atIndex: 0)
                }
            }
        }
        
        // Reload the Table View
        self.refreshTableViewAndEndSpinner(true)
    }
    
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
    
    
    // MARK: AWS METHODS
    
    // Add a record for an action between user connections
    func addUserConnectionAction(userID: String, connectionUserID: String, actionType: String) {
        print("ADDING CONNECTION ACTION: \(userID), \(connectionUserID), \(actionType)")
        let json: NSDictionary = [
            "user_id"               : userID
            , "connection_user_id"  : connectionUserID
            , "action_type"         : actionType
        ]
        
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        lambdaInvoker.invokeFunction("Blobjot-AddUserConnectionAction", JSONObject: json, completionHandler: { (response, err) -> Void in
            
            if (err != nil) {
                print("ADD CONNECTION ACTION ERROR: \(err)")
            } else if (response != nil) {
                print("PVC-ACA: response: \(response)")
            }
        })
    }
    
    // The initial request for Map Blob data - called when the View Controller is instantiated
    func getUserConnections() {
        print("PVC - \(self.printCheck): REQUESTING GUC")
        
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["user_id" : Constants.Data.currentUser, "print_check" : self.printCheck]
        
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        lambdaInvoker.invokeFunction("Blobjot-GetUserConnections", JSONObject: json, completionHandler: { (response, err) -> Void in
            
            if (err != nil) {
                print("PVC - \(self.printCheck): GET USER CONNECTIONS DATA ERROR: \(err)")
            } else if (response != nil) {
                
                // Convert the response to an array of arrays
                if let userConnectionArrays = response as? [[AnyObject]] {
                    
                    // Loop through the arrays and add each user - the arrays should be in the proper order by user type
                    for (arrayIndex, userArray) in userConnectionArrays.enumerate() {
                        print("PVC-GUC - \(self.printCheck): array: \(arrayIndex): jsonData: \(userArray)")
                        print("PVC - \(self.printCheck): USER COUNT: \(userArray.count)")
                        
                        // Stop the table loading spinner before adding data so that it does not show up in front of the user list
                        //                        self.accountTableActivityIndicator.stopAnimating()
                        
                        // Loop through each AnyObject (User) in the array
                        for user in userArray {
                            print("PVC - \(self.printCheck): USER: \(user)")
                            
                            // Convert the AnyObject to JSON with keys and AnyObject values
                            // Then convert the AnyObject values to Strings or Numbers depending on their key
                            if let checkUser = user as? [String: AnyObject] {
                                let userID = checkUser["user_id"] as! String
                                let userName = checkUser["user_name"] as! String
                                let userImageKey = checkUser["user_image_key"] as! String
                                print("PVC - \(self.printCheck): USER ID: \(userID)")
                                print("PVC - \(self.printCheck): USER NAME: \(userName)")
                                print("PVC - \(self.printCheck): USER IMAGE KEY: \(userImageKey)")
                                
                                // Create a User Object and add it to the global User array
                                let addUser = User()
                                addUser.userID = userID
                                addUser.userName = userName
                                addUser.userImageKey = userImageKey
                                addUser.userStatus = Constants.UserStatusTypes(rawValue: arrayIndex)
                                
                                print("PVC - TRYING TO ADD DOWNLOADED USER: \(userName)")
                                
                                // Check to ensure the user does not already exist in the global User array
                                var userObjectExists = false
                                loopUserObjectCheck: for userObject in Constants.Data.userObjects {
                                    if userObject.userID == userID {
                                        userObject.userName = userName
                                        userObject.userImageKey = userImageKey
                                        userObject.userStatus = Constants.UserStatusTypes(rawValue: arrayIndex)
                                        
                                        userObjectExists = true
                                        break loopUserObjectCheck
                                    }
                                }
                                if userObjectExists == false {
                                    print("USER: \(userName) DOES NOT EXIST - ADDING")
                                    Constants.Data.userObjects.append(addUser)
                                }
                                
                                //Alert the parent view controller (if needed) that the logged in user should be in the global array
                                if addUser.userID == Constants.Data.currentUser {
                                    
                                    // Call the parent VC to alert that the logged in user has been added to the global user list
                                    if let parentVC = self.peopleViewDelegate {
                                        parentVC.userObjectListUpdatedWithCurrentUser()
                                        print("FOUND LOGGED IN USER \(addUser.userName)")
                                    }
                                }
                                
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
                                    
                                    // Add the User Object to the local list only if it is not the currently logged in user
                                    // If it is the logged in user, assign the userName to the displayUserTextField
                                    if addUser.userID != Constants.Data.currentUser {
                                        
                                        self.peopleList.append(addUser)
                                        print("PVC - \(self.printCheck): ADDED USER \(addUser.userName) TO PEOPLE LIST")
                                        
                                    }
                                }
                                print("PVC - \(self.printCheck): PEOPLE LIST COUNT: \(self.peopleList.count)")
                            }
                        }
                    }
                    // Find the passed person, remove them from their position in the list and place them at the top (index: 0) position
                    self.bringTopPersonToFrontOfPeopleList()
                    
//                    // Reload the Table View
//                    self.refreshTableViewAndEndSpinner(true)
                }
            }
        })
    }
    
    // Download User Image
    func getUserImage(userID: String, imageKey: String) {
        print("PVC - \(self.printCheck): GETTING IMAGE FOR: \(imageKey)")
        
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
                    print("PVC - \(self.printCheck): DOWNLOAD PAUSED")
                } else {
                    print("PVC - \(self.printCheck): DOWNLOAD FAILED: [\(error)]")
                }
            } else if let exception = task.exception {
                print("PVC - \(self.printCheck): DOWNLOAD FAILED: [\(exception)]")
            } else {
                print("PVC - \(self.printCheck): DOWNLOAD SUCCEEDED")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    // Assign the image to the Preview Image View
                    if NSFileManager().fileExistsAtPath(downloadingFilePath) {
                        print("IMAGE FILE AVAILABLE")
                        let thumbnailData = NSData(contentsOfFile: downloadingFilePath)
                        
                        // Ensure the Thumbnail Data is not null
                        if let tData = thumbnailData {
                            print("GET IMAGE - CHECK 1")
                            
                            // Find the correct User Object in the global list and assign the newly downloaded Image
                            loopUserObjectCheck: for userObject in Constants.Data.userObjects {
                                if userObject.userID == userID {
                                    userObject.userImage = UIImage(data: tData)
                                    
                                    break loopUserObjectCheck
                                }
                            }
                            // Find the correct User Object in the local list and assign the newly downloaded Image
                            loopUserObjectCheckLocal: for userObjectLocal in self.peopleList {
                                if userObjectLocal.userID == userID {
                                    userObjectLocal.userImage = UIImage(data: tData)
                                    
                                    break loopUserObjectCheckLocal
                                }
                            }
                            
                            print("ADDED IMAGE: \(imageKey))")
                            
                            // Reload the Table View
                            self.refreshTableViewAndEndSpinner(false)
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
