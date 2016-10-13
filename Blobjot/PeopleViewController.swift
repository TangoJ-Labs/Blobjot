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

class PeopleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate, AWSRequestDelegate {

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
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        navBarHeight = self.navigationController?.navigationBar.frame.height
        print("**************** PVC - \(self.printCheck) - NAV BAR HEIGHT: \(navBarHeight)")
        viewFrameY = self.view.frame.minY
        print("**************** PVC - \(self.printCheck) - VIEW FRAME Y: \(viewFrameY)")
        screenSize = UIScreen.main.bounds
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
        searchBar.barStyle = .default
        searchBar.backgroundImage = UtilityFunctions().getImageWithColor(Constants.Colors.colorStatusBar, size: CGSize(width: 5, height: 5))
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
        searchExitLabel.backgroundColor = UIColor.clear
        searchExitLabel.text = "\u{2573}"
        searchExitLabel.textAlignment = .center
        searchExitLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
        searchExitLabel.textColor = UIColor.white
        searchExitView.addSubview(searchExitLabel)
        
//        // Add a loading indicator while downloading the logged in user image
//        peopleTableViewActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: searchBarContainer.frame.height, width: viewContainer.frame.width, height: Constants.Dim.peopleTableViewCellHeight))
//        peopleTableViewActivityIndicator.color = UIColor.blackColor()
//        viewContainer.addSubview(peopleTableViewActivityIndicator)
//        peopleTableViewActivityIndicator.startAnimating()
        
        peopleTableView = UITableView(frame: CGRect(x: 0, y: searchBarContainer.frame.height, width: viewContainer.frame.width, height: viewContainer.frame.height - searchBarContainer.frame.height))
        peopleTableView.dataSource = self
        peopleTableView.delegate = self
        peopleTableView.register(PeopleTableViewCell.self, forCellReuseIdentifier: Constants.Strings.peopleTableViewCellReuseIdentifier)
        peopleTableView.separatorStyle = .none
        peopleTableView.backgroundColor = UIColor.clear
        peopleTableView.allowsSelection = true
        peopleTableView.alwaysBounceVertical = true
        peopleTableView.showsVerticalScrollIndicator = false
        viewContainer.addSubview(peopleTableView)
        
        // Create a refresh control for the CollectionView and add a subview to move the refresh control where needed
//        refreshView = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: 40))
//        peopleTableView.addSubview(refreshView)
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "")
        refreshControl.addTarget(self, action: #selector(PeopleViewController.refreshDataManually), for: UIControlEvents.valueChanged)
        peopleTableView.addSubview(refreshControl)
        peopleTableView.contentOffset = CGPoint(x: 0, y: -self.refreshControl.frame.size.height)
        refreshControl.beginRefreshing()
        
        cellPeopleTableViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(PeopleViewController.tapPeopleTableView(_:)))
        cellPeopleTableViewTapGesture.numberOfTapsRequired = 1  // add single tap
        peopleTableView.addGestureRecognizer(cellPeopleTableViewTapGesture)
        
        searchExitTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapSearchExit(_:)))
        searchExitTapGesture.numberOfTapsRequired = 1  // add single tap
        searchExitView.addGestureRecognizer(searchExitTapGesture)
        
        AWSPrepRequest(requestToCall: AWSGetUserConnections(), delegate: self as AWSRequestDelegate).prepRequest()
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        print("PVC - \(self.printCheck) - PEOPLE LIST COUNT: \(self.peopleList.count)")
        return self.peopleList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.Dim.accountTableViewCellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.peopleTableViewCellReuseIdentifier, for: indexPath) as! PeopleTableViewCell
        print("CELL \((indexPath as NSIndexPath).row): \(cell)")
        
        cell.cellUserName.text = ""
        cell.cellUserImage.image = nil
        cell.cellConnectStar.image = UIImage(named: Constants.Strings.imageStringStarEmpty)
        cell.cellActionMessage.text = ""
        cell.cellUserImageActivityIndicator.startAnimating()
        
        // Add a clear background for the selectedBackgroundView so that the row is not highlighted when selected
        let sbv = UIView(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height))
        sbv.backgroundColor = UIColor.clear
        cell.selectedBackgroundView = sbv
        
        let cellUserObject = self.peopleList[(indexPath as NSIndexPath).row]
        print("USER NAME: \(cellUserObject.userName) FOR CELL: \((indexPath as NSIndexPath).row)")
        
        // Get the User Object from the list and assign data to the cell
        cell.cellUserName.text = cellUserObject.userName
        if let cellUserImage = cellUserObject.userImage {
            cell.cellUserImage.image = cellUserImage
            
            cell.cellUserImageActivityIndicator.stopAnimating()
        } else {
            AWSPrepRequest(requestToCall: AWSGetUserImage(user: cellUserObject), delegate: self as AWSRequestDelegate).prepRequest()
        }
        
        print("USER STATUS: \(cellUserObject.userStatus)")
        if cellUserObject.userStatus == Constants.UserStatusTypes.pending {
            cell.cellConnectStar.image = UIImage(named: Constants.Strings.imageStringStarHalfFilled)
            cell.cellActionMessage.text = "Pending Request..."
        } else if cellUserObject.userStatus == Constants.UserStatusTypes.waiting {
            cell.cellConnectStar.image = UIImage(named: Constants.Strings.imageStringStarHalfFilled)
            cell.cellActionMessage.text = "Waiting for Response..."
        } else if cellUserObject.userStatus == Constants.UserStatusTypes.connected {
            cell.cellConnectStar.image = UIImage(named: Constants.Strings.imageStringStarFilled)
            cell.cellActionMessage.text = ""
        } else if cellUserObject.userStatus == Constants.UserStatusTypes.blocked {
            cell.cellConnectStar.image = UIImage(named: Constants.Strings.imageStringStarEmpty)
            cell.cellActionMessage.text = "User Blocked"
        } else {
            cell.cellConnectStar.image = UIImage(named: Constants.Strings.imageStringStarEmpty)
            cell.cellActionMessage.text = ""
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("DID SELECT ROW: \((indexPath as NSIndexPath).row)")
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
        return true
    }
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
//        editingStyle = UITableViewCellEditingStyle.Delete
    }
    
    // Return the action types for the row slide options
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        // Set the default return action
        let add = UITableViewRowAction(style: .normal, title: "Connect") { action, index in
            print("add connection button tapped")
            
            // Call to change the userStatus to 3 (NotConnected) and prepare the view
            self.updateUserStatusType(self.peopleList[(indexPath as NSIndexPath).row].userID, peopleListIndex: (indexPath as NSIndexPath).row, userStatus: Constants.UserStatusTypes.waiting)
        }
        add.backgroundColor = UIColor.yellow
        var returnActions = [add]
        
        // Check the user status type based on the index of the peopleList array (see the list in the User class)
        let rowUser = self.peopleList[(indexPath as NSIndexPath).row]
        print("IN ROW ACTIONS FOR ROW: \((indexPath as NSIndexPath).row) AND USER: \(rowUser.userName)")
        
        if rowUser.userStatus == Constants.UserStatusTypes.pending {
            // PENDING USERS
            print("IN PENDING USER ACTIONS")
            let block = UITableViewRowAction(style: .normal, title: "Block\nUser") { action, index in
                print("block button tapped")
                // Remove the person from the global people list
                loopUserObjectCheck: for (userIndex, userObject) in Constants.Data.userObjects.enumerated() {
                    if userObject.userID == self.peopleList[(indexPath as NSIndexPath).row].userID {
                        Constants.Data.userObjects.remove(at: userIndex)
                        
                        break loopUserObjectCheck
                    }
                }
                // Call to change the userStatus to 3 (NotConnected) and prepare the view
                self.updateUserStatusType(self.peopleList[(indexPath as NSIndexPath).row].userID, peopleListIndex: (indexPath as NSIndexPath).row, userStatus: Constants.UserStatusTypes.blocked)
            }
            block.backgroundColor = UIColor.black
            
            let delete = UITableViewRowAction(style: .normal, title: "Delete\nRequest") { action, index in
                print("delete request button tapped")
                
                // Call to change the userStatus to 3 (NotConnected) and prepare the view
                self.updateUserStatusType(self.peopleList[(indexPath as NSIndexPath).row].userID, peopleListIndex: (indexPath as NSIndexPath).row, userStatus: Constants.UserStatusTypes.notConnected)
            }
            delete.backgroundColor = UIColor.red
            
            let add = UITableViewRowAction(style: .normal, title: "Connect") { action, index in
                print("add connection button tapped")
                
                // Call to change the userStatus to 3 (NotConnected) and prepare the view
                self.updateUserStatusType(self.peopleList[(indexPath as NSIndexPath).row].userID, peopleListIndex: (indexPath as NSIndexPath).row, userStatus: Constants.UserStatusTypes.connected)
            }
            add.backgroundColor = UIColor.yellow
            
            returnActions = [add, delete, block]
            
        } else if rowUser.userStatus == Constants.UserStatusTypes.waiting {
            // WAITING USERS
            print("IN WAITING USER ACTIONS")
            let delete = UITableViewRowAction(style: .normal, title: "Delete\nRequest") { action, index in
                print("delete request button tapped")
                
                // Call to change the userStatus to 3 (NotConnected) and prepare the view
                self.updateUserStatusType(self.peopleList[(indexPath as NSIndexPath).row].userID, peopleListIndex: (indexPath as NSIndexPath).row, userStatus: Constants.UserStatusTypes.notConnected)
            }
            delete.backgroundColor = UIColor.red
            
            returnActions = [delete]
            
        } else if rowUser.userStatus == Constants.UserStatusTypes.connected {
            // CONNECTED USERS
            print("IN CONNECTED USER ACTIONS")
            let delete = UITableViewRowAction(style: .normal, title: "Delete\nConnection") { action, index in
                print("delete connection button tapped")
                
                // Call to change the userStatus to 3 (NotConnected) and prepare the view
                self.updateUserStatusType(self.peopleList[(indexPath as NSIndexPath).row].userID, peopleListIndex: (indexPath as NSIndexPath).row, userStatus: Constants.UserStatusTypes.notConnected)
            }
            delete.backgroundColor = UIColor.red
            
            returnActions = [delete]
        } else if rowUser.userStatus == Constants.UserStatusTypes.blocked {
            // CONNECTED USERS
            print("IN BLOCKED USER ACTIONS")
            let delete = UITableViewRowAction(style: .normal, title: "Unblock\nUser") { action, index in
                print("unblock user button tapped")
                
                // Call to change the userStatus to 3 (NotConnected) and prepare the view
                self.updateUserStatusType(self.peopleList[(indexPath as NSIndexPath).row].userID, peopleListIndex: (indexPath as NSIndexPath).row, userStatus: Constants.UserStatusTypes.notConnected)
            }
            delete.backgroundColor = UIColor.red
            
            returnActions = [delete]
        }
        
        print("RETURNING ROW ACTIONS")
        return returnActions
    }
    
    // The user swiped down on the Table View - delete all data and re-download
    func refreshDataManually(_ sender: AnyObject) {
        print("PVC - MANUALLY REFRESH TABLE")
        // Clear the current peopleList and any selections
        self.peopleList = [User]()
        self.selectedPeopleList = [User]()
        
        // Clear the Table View
        self.refreshTableViewAndEndSpinner(false)
        
        // Recall the data
        AWSPrepRequest(requestToCall: AWSGetUserConnections(), delegate: self as AWSRequestDelegate).prepRequest()
    }
    
    
    // MARK:  UISearchBarDelegate protocol
    
    // Edit the peopleList based on the search text filter
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
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
                if userObject.userName.lowercased().contains(searchText.lowercased()) {
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
    
    func updateSearchResults(for searchController: UISearchController) {
        print("UPDATE SEARCH RESULTS FOR SEARCH CONTROLLER: \(searchController)")
    }
    
    
    // MARK: GESTURE METHODS
    
    func tapSearchExit(_ gesture: UITapGestureRecognizer) {
        searchBar.resignFirstResponder()
    }
    
    func tapPeopleTableView(_ gesture: UITapGestureRecognizer) {
        let tapPoint = gesture.location(in: peopleTableView)
        print("TAP POINT: \(tapPoint)")
        let iPath = peopleTableView.indexPathForRow(at: tapPoint)
        
        if let indexPath = iPath {
            let cell = peopleTableView.dequeueReusableCell(withIdentifier: Constants.Strings.peopleTableViewCellReuseIdentifier, for: indexPath) as! PeopleTableViewCell
            print("CELL \((indexPath as NSIndexPath).row): \(cell)")
            
            let pointInCell = gesture.location(in: cell.cellContainer)
            print("CELL STAR FRAME: \(cell.cellConnectStar.frame)")
            print("POINT IN CELL: \(pointInCell.x), \(pointInCell.y)")
            if cell.cellConnectStar.frame.contains(pointInCell) {
                print("TOUCH IN STAR")
                
                // Check the user status type based on the index of the peopleList array (see the list in the User class)
                let rowUser = self.peopleList[(indexPath as NSIndexPath).row]
                print("IN ROW ACTIONS FOR ROW: \((indexPath as NSIndexPath).row) AND USER: \(rowUser.userName)")
                
                // Set default userStatus settings
                var userStatus = Constants.UserStatusTypes.waiting
                
                if rowUser.userStatus == Constants.UserStatusTypes.pending {
                    // PENDING USERS
                    print("TAPPED PENDING USER STAR")
                    // Change the userStatus to 3 (Other) and set the actionType to delete
                    userStatus = Constants.UserStatusTypes.connected
                    
                } else if rowUser.userStatus == Constants.UserStatusTypes.waiting || rowUser.userStatus == Constants.UserStatusTypes.connected || rowUser.userStatus == Constants.UserStatusTypes.blocked {
                    // WAITING, CONNECTED, OR BLOCKED USERS
                    print("TAPPED WAITING, CONNECTED, OR BLOCKED USER STAR")
                    // Change the userStatus to 3 (Other) and set the actionType to delete
                    userStatus = Constants.UserStatusTypes.notConnected
                    
                } else {
                    // NOT CONNECTED USERS - will keep default "Waiting" status type set above
                    print("TAPPED NOT CONNECTED USER STAR")
                }
                
                updateUserStatusType(self.peopleList[(indexPath as NSIndexPath).row].userID, peopleListIndex: (indexPath as NSIndexPath).row, userStatus: userStatus)
                
            } else if cell.cellUserImage.frame.contains(pointInCell) {
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
    
    func popViewController(_ sender: UIBarButtonItem) {
        print("pop Back to Account View")
        self.dismiss(animated: true, completion: {
        })
    }
    
    func updateUserStatusType(_ counterpartUserID: String, peopleListIndex: Int, userStatus: Constants.UserStatusTypes) {
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
        if userStatus == Constants.UserStatusTypes.notConnected {
            actionType = "delete"
        } else if userStatus == Constants.UserStatusTypes.blocked {
            actionType = "block"
        }
        
        // Add a user connection action in AWS
        AWSPrepRequest(requestToCall: AWSAddUserConnectionAction(userID: Constants.Data.currentUser, connectionUserID: counterpartUserID, actionType: actionType), delegate: self as AWSRequestDelegate).prepRequest()
    }
    
    func refreshTableViewAndEndSpinner(_ endSpinner: Bool) {
        // Sort the list in case the userStatuses were changed
//        self.peopleList.sortInPlace({$0.userStatus.rawValue <  $1.userStatus.rawValue})
        
        // Reload the Table View
        print("GET DATA - RELOAD TABLE VIEW")
        self.peopleTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
        
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
            for (index, person) in peopleList.enumerated() {
                if person.userID == self.peopleListTopPerson {
                    peopleList.remove(at: index)
                    peopleList.insert(person, at: 0)
                }
            }
        }
        
        // Reload the Table View
        self.refreshTableViewAndEndSpinner(true)
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen() {
        print("PVC - SHOW LOGIN SCREEN")
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
        DispatchQueue.main.async(execute:
            {
                // Process the return data based on the method used
                switch objectType
                {
                case _ as AWSAddUserConnectionAction:
                    if !success
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case let awsGetUserConnections as AWSGetUserConnections:
                    if success
                    {
                        // Loop through the arrays and add each user - the arrays should be in the proper order by user type
                        for (arrayIndex, userArray) in awsGetUserConnections.userConnectionArrays.enumerated() {
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
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case let awsGetUserImage as AWSGetUserImage:
                    if success
                    {
                        if let newImage = awsGetUserImage.user.userImage
                        {
                            // Find the correct User Object in the local list and assign the newly downloaded Image
                            loopUserObjectCheckLocal: for userObjectLocal in self.peopleList {
                                if userObjectLocal.userID == awsGetUserImage.user.userID {
                                    userObjectLocal.userImage = newImage
                                    
                                    break loopUserObjectCheckLocal
                                }
                            }
                            
                            print("PVC - ADDED USER IMAGE: \(awsGetUserImage.user.userImageKey))")
                            
                            // Reload the Table View
                            self.refreshTableViewAndEndSpinner(false)
                        }
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                default:
                    print("PVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    // Show the error message
                    let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    self.present(alertController, animated: true, completion: nil)
                }
        })
    }

}
