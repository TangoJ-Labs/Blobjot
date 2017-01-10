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
protocol PeopleViewControllerDelegate
{
    // When called, the parent View Controller checks for changes to the logged in user
    func logoutUser()
    
    // When called, fire the parent popViewController
    func popViewController()
}

class PeopleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate, AWSRequestDelegate
{
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
    
    var peopleListTopPerson: String?
    var peopleList = Constants.Data.userObjects
    
    var printCheck = ""
    
    // Property Indicators
    var useBarHeights = true
    var tabBarUsed = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Status Bar Settings
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        print("**************** STATUS BAR HEIGHT: \(statusBarHeight)")
        navBarHeight = 0
        if let navController = self.navigationController
        {
            navBarHeight = navController.navigationBar.frame.height
        }
        print("**************** navBarHeight: \(navBarHeight)")
        viewFrameY = self.view.frame.minY
        print("**************** VIEW FRAME Y: \(viewFrameY)")

        screenSize = UIScreen.main.bounds
        
        if !useBarHeights
        {
            statusBarHeight = 0
            navBarHeight = 0
        }
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: statusBarHeight + navBarHeight - viewFrameY, width: self.view.frame.width, height: self.view.frame.height - statusBarHeight - navBarHeight + viewFrameY))
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        self.view.addSubview(viewContainer)
        
        searchBarContainer = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width - Constants.Dim.peopleSearchBarHeight, height: Constants.Dim.peopleSearchBarHeight))
        searchBarContainer.backgroundColor = Constants.Colors.colorStatusBar
        viewContainer.addSubview(searchBarContainer)
        
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: searchBarContainer.frame.width, height: searchBarContainer.frame.height))
        searchBar.delegate = self
        searchBar.barStyle = .default
        searchBar.backgroundImage = UtilityFunctions().getImageWithColor(Constants.Colors.colorStatusBar, size: CGSize(width: 5, height: 5))
        searchBar.tintColor = Constants.Colors.colorStatusBar
        searchBarContainer.addSubview(searchBar)
        
        // Add the Search Exit Button to close the keyboard
        searchExitView = UIView(frame: CGRect(x: searchBarContainer.frame.width, y: 0, width: Constants.Dim.peopleSearchBarHeight, height: Constants.Dim.peopleSearchBarHeight))
        searchExitView.backgroundColor = Constants.Colors.colorStatusBar
        viewContainer.addSubview(searchExitView)
        
        searchExitLabel = UILabel(frame: CGRect(x: 5, y: 5, width: Constants.Dim.peopleSearchBarHeight - 10, height: Constants.Dim.peopleSearchBarHeight - 10))
        searchExitLabel.backgroundColor = UIColor.clear
        searchExitLabel.text = "\u{2573}"
        searchExitLabel.textAlignment = .center
        searchExitLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
        searchExitLabel.textColor = Constants.Colors.colorTextNavBar
        searchExitView.addSubview(searchExitLabel)
        
        // Add a loading indicator while downloading the logged in user image
        peopleTableViewActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: searchBarContainer.frame.height, width: viewContainer.frame.width, height: Constants.Dim.peopleTableViewCellHeight))
        peopleTableViewActivityIndicator.color = UIColor.black
        viewContainer.addSubview(peopleTableViewActivityIndicator)
        peopleTableViewActivityIndicator.startAnimating()
        
        var tableViewHeightAdjust: CGFloat = 0
        if self.tabBarUsed
        {
            tableViewHeightAdjust = Constants.Dim.tabBarHeight
        }
        
        peopleTableView = UITableView(frame: CGRect(x: 0, y: searchBarContainer.frame.height, width: viewContainer.frame.width, height: viewContainer.frame.height - searchBarContainer.frame.height - tableViewHeightAdjust))
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
        
        cellPeopleTableViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(PeopleViewController.tapPeopleTableView(_:)))
        cellPeopleTableViewTapGesture.numberOfTapsRequired = 1  // add single tap
        peopleTableView.addGestureRecognizer(cellPeopleTableViewTapGesture)
        
        searchExitTapGesture = UITapGestureRecognizer(target: self, action: #selector(PeopleViewController.tapSearchExit(_:)))
        searchExitTapGesture.numberOfTapsRequired = 1  // add single tap
        searchExitView.addGestureRecognizer(searchExitTapGesture)
        
//        UtilityFunctions().resetUserListWithCoreData()
        
        // Populate the local User list with the global User list
        // The global User list was populated from Core Data upon initiation, and was updated with new data upon download
        peopleList = Constants.Data.userObjects
        
        if let tabBar = self.tabBarController
        {
            let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
            let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
            ncTitleText.text = "People"
            ncTitleText.font = UIFont(name: Constants.Strings.fontRegular, size: 14)
            ncTitleText.textColor = Constants.Colors.colorTextNavBar
            ncTitleText.textAlignment = .center
            ncTitle.addSubview(ncTitleText)
            tabBar.navigationItem.titleView = ncTitle
        }
    }
    
    override func viewWillLayoutSubviews()
    {
        AWSPrepRequest(requestToCall: AWSGetUserConnections(), delegate: self as AWSRequestDelegate).prepRequest()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if self.peopleList.count > 0
        {
            // Hide the activityIndicator - cells are shown, and it should be hidden anyway (the refresh spinner will be used in manual refreshing)
            self.peopleTableViewActivityIndicator.stopAnimating()
            self.peopleTableViewActivityIndicator.isHidden = true
        }
        
        return self.peopleList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return Constants.Dim.peopleTableViewCellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.peopleTableViewCellReuseIdentifier, for: indexPath) as! PeopleTableViewCell
        cell.cellUserName.text = ""
        cell.cellUserImage.image = nil
        cell.cellConnectIndicator.image = UIImage(named: Constants.Strings.iconStringConnectionViewAddConnection)
        cell.cellActionMessage.text = ""
        cell.cellUserImageActivityIndicator.startAnimating()
        
        // Add a clear background for the selectedBackgroundView so that the row is not highlighted when selected
        let sbv = UIView(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height))
        sbv.backgroundColor = UIColor.clear
        cell.selectedBackgroundView = sbv
        
        let cellUserObject = self.peopleList[(indexPath as NSIndexPath).row]
        
        // Get the User Object from the list and assign data to the cell
        if cellUserObject.userName != nil
        {
            cell.cellUserName.text = cellUserObject.userName
            
            if let cellUserImage = cellUserObject.userImage
            {
                cell.cellUserImage.image = cellUserImage
                cell.cellUserImageActivityIndicator.stopAnimating()
            }
            else
            {
                AWSPrepRequest(requestToCall: FBGetUserProfileData(user: cellUserObject, downloadImage: true), delegate: self as AWSRequestDelegate).prepRequest()
            }
        }
        else
        {
            AWSPrepRequest(requestToCall: FBGetUserProfileData(user: cellUserObject, downloadImage: true), delegate: self as AWSRequestDelegate).prepRequest()
        }
        
        if cellUserObject.userStatus == Constants.UserStatusTypes.following
        {
            cell.cellConnectIndicator.image = UIImage(named: Constants.Strings.iconStringConnectionViewPending)
            cell.cellActionMessage.text = "Following"
        }
        else if cellUserObject.userStatus == Constants.UserStatusTypes.notFollowing
        {
            cell.cellConnectIndicator.image = UIImage(named: Constants.Strings.iconStringConnectionViewCheck)
            cell.cellActionMessage.text = ""
        }
        else if cellUserObject.userStatus == Constants.UserStatusTypes.blocked
        {
            cell.cellConnectIndicator.image = UIImage(named: Constants.Strings.iconStringConnectionViewAddConnection)
            cell.cellActionMessage.text = "User Blocked"
        }
        else
        {
            cell.cellConnectIndicator.image = UIImage(named: Constants.Strings.iconStringConnectionViewAddConnection)
            cell.cellActionMessage.text = ""
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
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
    
    // Return the action types for the row slide options
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        // Check the user status type based on the index of the peopleList array (see the list in the User class)
        let rowUser = self.peopleList[(indexPath as NSIndexPath).row]
        
        if let rowUserID = rowUser.userID
        {
            if rowUser.userID == Constants.Data.currentUser.userID
            {
                // LOGGED IN USER
                let you = UITableViewRowAction(style: .normal, title: "This is\nYou!")
                { action, index in
                    print("PVC - current user button tapped")
                }
                you.backgroundColor = Constants.Colors.colorGrayLight
                
                return [you]
            }
            else if rowUser.userStatus == Constants.UserStatusTypes.following
            {
                // FOLLOWING USERS
                let delete = UITableViewRowAction(style: .normal, title: "Unfollow")
                { action, index in
                    // Call to change the userStatus to 1 (NotFollowing) and prepare the view
                    self.updateUserStatusType(rowUserID, peopleListIndex: (indexPath as NSIndexPath).row, userStatus: Constants.UserStatusTypes.notFollowing)
                }
                delete.backgroundColor = Constants.Colors.blobRedOpaque
                
                return [delete]
            }
            else if rowUser.userStatus == Constants.UserStatusTypes.notFollowing
            {
                // NOT FOLLOWING USERS
                let block = UITableViewRowAction(style: .normal, title: "Block\nUser")
                { action, index in
                    // Remove the person from the global people list
                    loopUserObjectCheck: for (userIndex, userObject) in Constants.Data.userObjects.enumerated()
                    {
                        if userObject.userID == self.peopleList[(indexPath as NSIndexPath).row].userID
                        {
                            Constants.Data.userObjects.remove(at: userIndex)
                            
                            break loopUserObjectCheck
                        }
                    }
                    // Call to change the userStatus to 2 (Blocked) and prepare the view
                    self.updateUserStatusType(rowUserID, peopleListIndex: (indexPath as NSIndexPath).row, userStatus: Constants.UserStatusTypes.blocked)
                }
                block.backgroundColor = Constants.Colors.colorGrayLight
                
                let add = UITableViewRowAction(style: .normal, title: "Follow")
                { action, index in
                    // Call to change the userStatus to 0 (Following) and prepare the view
                    self.updateUserStatusType(rowUserID, peopleListIndex: (indexPath as NSIndexPath).row, userStatus: Constants.UserStatusTypes.following)
                }
                add.backgroundColor = Constants.Colors.blobYellowOpaque
                
                return [add, block]
            }
            else if rowUser.userStatus == Constants.UserStatusTypes.blocked
            {
                // BLOCKED USERS
                let delete = UITableViewRowAction(style: .normal, title: "Unblock\nUser")
                { action, index in
                    // Call to change the userStatus to 2 (NotFollowing) and prepare the view
                    self.updateUserStatusType(rowUserID, peopleListIndex: (indexPath as NSIndexPath).row, userStatus: Constants.UserStatusTypes.notFollowing)
                }
                delete.backgroundColor = Constants.Colors.blobRedOpaque
                
                return [delete]
            }
            else
            {
                // NOT FOLLOWING USERS
                let block = UITableViewRowAction(style: .normal, title: "Block\nUser")
                { action, index in
                    // Remove the person from the global people list
                    loopUserObjectCheck: for (userIndex, userObject) in Constants.Data.userObjects.enumerated()
                    {
                        if userObject.userID == self.peopleList[(indexPath as NSIndexPath).row].userID
                        {
                            Constants.Data.userObjects.remove(at: userIndex)
                            
                            break loopUserObjectCheck
                        }
                    }
                    // Call to change the userStatus to 2 (Blocked) and prepare the view
                    self.updateUserStatusType(rowUserID, peopleListIndex: (indexPath as NSIndexPath).row, userStatus: Constants.UserStatusTypes.blocked)
                }
                block.backgroundColor = Constants.Colors.colorGrayLight
                
                let add = UITableViewRowAction(style: .normal, title: "Follow")
                { action, index in
                    // Call to change the userStatus to 0 (Following) and prepare the view
                    self.updateUserStatusType(rowUserID, peopleListIndex: (indexPath as NSIndexPath).row, userStatus: Constants.UserStatusTypes.following)
                }
                add.backgroundColor = Constants.Colors.blobYellowOpaque
                
                return [add, block]
            }
        }
        else
        {
            // ERROR WITH ROW USER
            let nothing = UITableViewRowAction(style: .normal, title: "Error,\nplease reload")
            { action, index in
                print("PVC - current user button tapped")
            }
            nothing.backgroundColor = Constants.Colors.colorGrayLight
            return [nothing]
        }
    }
    
    // The user swiped down on the Table View - delete all data and re-download
    func refreshDataManually(_ sender: AnyObject)
    {
        // Clear the current peopleList and any selections
        self.peopleList = Constants.Data.userObjects
        
        // Clear the Table View
        self.refreshTableViewAndEndSpinner(false)
        
        // Recall the data
        AWSPrepRequest(requestToCall: AWSGetUserConnections(), delegate: self as AWSRequestDelegate).prepRequest()
    }
    
    
    // MARK:  UISearchBarDelegate protocol
    
    // Edit the peopleList based on the search text filter
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        // If the search bar is cleared, clear the peopleList and add all but the currently logged in user
        self.peopleList = [User]()
        if searchText == ""
        {
            for addPerson in Constants.Data.userObjects
            {
                self.peopleList.append(addPerson)
            }
            
            // else filter the list by clearing the peopleList and appending only the matching Users
        }
        else
        {
            self.peopleList = [User]()
            
            for userObject in Constants.Data.userObjects
            {
                if let username = userObject.userName
                {
                    // Convert the strings to lowercase for better matching
                    if username.lowercased().contains(searchText.lowercased())
                    {
                        self.peopleList.append(userObject)
                    }
                }
            }
        }
        self.refreshTableViewAndEndSpinner(true)
    }
    
    func updateSearchResults(for searchController: UISearchController)
    {
        print("PVC - UPDATE SEARCH RESULTS FOR SEARCH CONTROLLER: \(searchController)")
    }
    
    
    // MARK: GESTURE METHODS
    
    func tapSearchExit(_ gesture: UITapGestureRecognizer)
    {
        searchBar.resignFirstResponder()
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    func tapPeopleTableView(_ gesture: UITapGestureRecognizer)
    {
        let tapPoint = gesture.location(in: peopleTableView)
        let iPath = peopleTableView.indexPathForRow(at: tapPoint)
        
        if let indexPath = iPath
        {
            let cell = peopleTableView.dequeueReusableCell(withIdentifier: Constants.Strings.peopleTableViewCellReuseIdentifier, for: indexPath) as! PeopleTableViewCell
            
            let pointInCell = gesture.location(in: cell.cellContainer)
            if cell.cellConnectIndicator.frame.contains(pointInCell)
            {
                // Check the user status type based on the index of the peopleList array (see the list in the User class)
                let rowUser = self.peopleList[(indexPath as NSIndexPath).row]
                
                if let currentUserID = Constants.Data.currentUser.userID
                {
                    // Ensure that the tapped user is not the current user
                    if rowUser.userID != currentUserID
                    {
                        // Set default userStatus settings
                        var userStatus = Constants.UserStatusTypes.following
                        
                        if rowUser.userStatus == Constants.UserStatusTypes.notFollowing
                        {
                            // NOT FOLLOWING USERS
                            // Change the userStatus to 0 (Following)
                            userStatus = Constants.UserStatusTypes.following
                        
                        }
                        else if rowUser.userStatus == Constants.UserStatusTypes.following || rowUser.userStatus == Constants.UserStatusTypes.blocked
                        {
                            // FOLLOWING OR BLOCKED USERS
                            // Change the userStatus to 1 (NotFollowing)
                            userStatus = Constants.UserStatusTypes.notFollowing
                        }
                        
                        updateUserStatusType(self.peopleList[(indexPath as NSIndexPath).row].userID!, peopleListIndex: (indexPath as NSIndexPath).row, userStatus: userStatus)
                    }
                }
            }
            // Reload the Table View
            self.refreshTableViewAndEndSpinner(false)
        }
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    
    // MARK: CUSTOM FUNCTIONS
    
    func popViewController(_ sender: UIBarButtonItem)
    {
//        self.dismiss(animated: true, completion: {})
        self.navigationController!.popViewController(animated: true)
    }
    
    func updateUserStatusType(_ counterpartUserID: String, peopleListIndex: Int, userStatus: Constants.UserStatusTypes)
    {
        if let currentUserID = Constants.Data.currentUser.userID
        {
            // Update the associated user's userStatus locally and refresh the Table View
            self.peopleList[peopleListIndex].userStatus = userStatus
            self.refreshTableViewAndEndSpinner(true)
            
            // Update the associated user's userStatus globally
            loopUserObjectUpdate: for userObject in Constants.Data.userObjects
            {
                if userObject.userID == counterpartUserID
                {
                    userObject.userStatus = userStatus
                    
                    break loopUserObjectUpdate
                }
            }
            
            // Set the actionType - the initial type is the default
            var actionType = "connect"
            if userStatus == Constants.UserStatusTypes.notFollowing
            {
                actionType = "delete"
            }
            else if userStatus == Constants.UserStatusTypes.blocked
            {
                actionType = "block"
            }
            
            // Add a user connection action in AWS
            AWSPrepRequest(requestToCall: AWSAddUserConnectionAction(userID: currentUserID, connectionUserID: counterpartUserID, actionType: actionType), delegate: self as AWSRequestDelegate).prepRequest()
            
            // Save an action in Core Data
            CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
        }
    }
    
    func refreshTableViewAndEndSpinner(_ endSpinner: Bool)
    {
        // Sort the list in case the userStatuses were changed
        self.peopleList.sort(by: {
            if $0.userStatus.rawValue !=  $1.userStatus.rawValue
            {
                return $0.userStatus.rawValue <  $1.userStatus.rawValue
            }
            else
            {
                if $0.userName != nil && $1.userName != nil
                {
                    return $0.userName! <  $1.userName!
                }
                else
                {
                    return true
                }
            }
        })
        
        // Pull the selected user back to the top of the list
        if self.peopleListTopPerson != nil
        {
            self.bringTopPersonToFrontOfPeopleList()
        }
        else
        {
            // Reload the Table View
            self.peopleTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
        }
        
        if endSpinner
        {
            self.refreshControl.endRefreshing()
            self.peopleTableViewActivityIndicator.stopAnimating()
            self.peopleTableViewActivityIndicator.isHidden = true
        }
    }
    
    func bringTopPersonToFrontOfPeopleList()
    {
        // Ensure that the person was assigned
        if self.peopleListTopPerson != nil
        {
            // In the peopleList, find the person indicated to be at the top of the list
            // and move them to the beginning of the list.  Be sure to remove them from their current position.
            for (index, person) in peopleList.enumerated()
            {
                if person.userID == self.peopleListTopPerson
                {
                    peopleList.remove(at: index)
                    peopleList.insert(person, at: 0)
                }
            }
        }
        
        // Reload the Table View - DO NOT REPLACE THIS WITH LOCAL FUNCTION (function resorts users)
        self.peopleTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
        self.refreshControl.endRefreshing()
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
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
                case _ as AWSGetUserConnections:
                    if success
                    {
                        // Replace the local User list with the global one
                        self.peopleList = Constants.Data.userObjects
                        
                        // Find the passed person, remove them from their position in the list and place them at the top (index: 0) position
                        self.bringTopPersonToFrontOfPeopleList()
                        
                        // DO NOT RELOAD THE TABLE VIEW - "bringTopPersonToFrontOfPeopleList" WILL REFRESH
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case let FBGetUserProfileData as FBGetUserProfileData:
                    // Do not distinguish between success and failure for this class - both need to have the userList updated
                    // Find the correct User Object in the local list and assign the newly downloaded Image
                    loopUserObjectCheckLocal: for userObjectLocal in self.peopleList
                    {
                        if userObjectLocal.userID == FBGetUserProfileData.user.userID
                        {
                            // If the passed user has a userImage, use it, otherwise use the default image
                            if let newImage = FBGetUserProfileData.user.userImage
                            {
                                userObjectLocal.userImage = newImage
                            }
                            else
                            {
                                userObjectLocal.userImage = UIImage(named: Constants.Strings.iconStringDefaultProfile)
                            }
                            
                            // If the passed user has a username, use it, otherwise indicate a hidden user
                            if let username = FBGetUserProfileData.user.userName
                            {
                                userObjectLocal.userName = username
                            }
                            else
                            {
                                userObjectLocal.userName = "Hidden User"
                            }
                            
                            break loopUserObjectCheckLocal
                        }
                    }
                    
                    // Reload the Table View
                    self.refreshTableViewAndEndSpinner(true)
                    
                case _ as AWSGetSingleUserData:
                    if !success
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                default:
                    print("PVC - DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    // Show the error message
                    let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    self.present(alertController, animated: true, completion: nil)
                }
        })
    }

}
