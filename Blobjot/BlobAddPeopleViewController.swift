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
    func changeMapCircleType(_ type: Constants.BlobTypes)
    
    // Pass to the parent VC an indicator whether a person has been selected
    func selectedPerson()
    func deselectedAllPeople()
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
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        print("**************** BAPVC STATUS BAR HEIGHT: \(statusBarHeight)")
        viewFrameY = self.view.frame.minY
        print("**************** BAPVC VIEW FRAME Y: \(viewFrameY)")
        screenSize = UIScreen.main.bounds
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
        selectAllLabel.textAlignment = .left
        selectAllLabel.textColor = UIColor.white
        selectAllContainer.addSubview(selectAllLabel)
        
        selectAllBox = UILabel(frame: CGRect(x: selectAllWidth - 5 - selectBoxSize, y: (selectAllContainer.frame.height - selectBoxSize) / 2, width: selectBoxSize, height: selectBoxSize))
        selectAllBox.layer.borderColor = UIColor.white.cgColor
        selectAllBox.layer.borderWidth = 1
        selectAllBox.font = UIFont(name: Constants.Strings.fontRegular, size: 18)
        selectAllBox.text = ""
        selectAllBox.textAlignment = .center
        selectAllBox.textColor = UIColor.white
        selectAllContainer.addSubview(selectAllBox)
        
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: searchBarContainer.frame.width - selectAllWidth, height: searchBarContainer.frame.height))
        searchBar.delegate = self
        searchBar.barStyle = .default
        searchBar.backgroundImage = getImageWithColor(Constants.Colors.colorBlobAddPeopleSearchBar, size: CGSize(width: 5, height: 5))
        searchBar.tintColor = Constants.Colors.colorBlobAddPeopleSearchBar
        searchBarContainer.addSubview(searchBar)
        
        // Add a loading indicator while downloading the logged in user image
        peopleTableViewActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: searchBarContainer.frame.height, width: viewContainer.frame.width, height: Constants.Dim.blobAddPeopleTableViewCellHeight))
        peopleTableViewActivityIndicator.color = UIColor.black
        viewContainer.addSubview(peopleTableViewActivityIndicator)
        peopleTableViewActivityIndicator.startAnimating()
        
        peopleTableView = UITableView(frame: CGRect(x: 0, y: searchBar.frame.height, width: viewContainer.frame.width, height: viewContainer.frame.height - searchBar.frame.height))
        peopleTableView.dataSource = self
        peopleTableView.delegate = self
        peopleTableView.register(BlobAddPeopleTableViewCell.self, forCellReuseIdentifier: Constants.Strings.blobAddPeopleTableViewCellReuseIdentifier)
        peopleTableView.separatorStyle = .none
        peopleTableView.allowsMultipleSelection = true
        peopleTableView.backgroundColor = UIColor.clear
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
//        print("BAPVC - PEOPLE VIEW CONTAINER: \(peopleViewContainer.frame)")
//        peopleViewController.view.frame = CGRect(x: 0, y: 0, width: peopleViewContainer.frame.width, height: peopleViewContainer.frame.height)
//        peopleViewContainer.addSubview(peopleViewController.view)
//        peopleViewController.didMoveToParentViewController(self)
        
        selectAllMessage = UITextView(frame: CGRect(x: 0, y: searchBar.frame.height, width: viewContainer.frame.width, height: viewContainer.frame.height - searchBar.frame.height))
        selectAllMessage.backgroundColor = Constants.Colors.colorBlobAddPeopleSearchBar
        selectAllMessage.isEditable = false
        selectAllMessage.isScrollEnabled = false
        selectAllMessage.font = UIFont(name: Constants.Strings.fontRegular, size: 26)
        selectAllMessage.text = "Visible to\nall connections."
        selectAllMessage.textAlignment = .center
        selectAllMessage.textColor = UIColor.white
        
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        print("BAPVC - PEOPLE COUNT: \(peopleListUse.count)")
        return peopleListUse.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.Dim.blobAddPeopleTableViewCellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.blobAddPeopleTableViewCellReuseIdentifier, for: indexPath) as! BlobAddPeopleTableViewCell
        print("BAPVC - CELL \((indexPath as NSIndexPath).row): \(cell)")
        
        cell.cellUserImageActivityIndicator.startAnimating()
        
        // Add a clear background for the selectedBackgroundView so that the row is not highlighted when selected
        let sbv = UIView(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height))
        sbv.backgroundColor = Constants.Colors.colorPurple
        cell.selectedBackgroundView = sbv
        
        let cellUserObject = self.peopleListUse[(indexPath as NSIndexPath).row]
        print("BAPVC - USER NAME: \(cellUserObject.userName) FOR CELL: \((indexPath as NSIndexPath).row)")
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("DID SELECT ROW: \((indexPath as NSIndexPath).row)")
        
        // Add the selected person to the selected list if they do not already exist
        var personExists = false
        loopPeopleListSelected: for person in peopleListSelected {
            if person.userID == peopleListUse[(indexPath as NSIndexPath).row].userID {
                personExists = true
                break loopPeopleListSelected
            }
        }
        if !personExists {
            peopleListSelected.append(peopleListUse[(indexPath as NSIndexPath).row])
        }
        
        print("PEOPLE SELECTED COUNT: \(peopleListSelected.count)")
        // Check the number of people selected
        if peopleListSelected.count > 0 {
            if let parentVC = self.blobAddPeopleDelegate {
                parentVC.selectedPerson()
            }
        } else {
            if let parentVC = self.blobAddPeopleDelegate {
                parentVC.deselectedAllPeople()
            }
        }
        
        // SELECTED PEOPLE CHECK
        for person in peopleListSelected {
            print("PERSON SELECTED: \(person.userName)")
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        print("DID DESELECT ROW: \((indexPath as NSIndexPath).row)")
        
        loopPeopleListSelected: for (index, person) in peopleListSelected.enumerated() {
            if person.userID == peopleListUse[(indexPath as NSIndexPath).row].userID {
                peopleListSelected.remove(at: index)
                break loopPeopleListSelected
            }
        }
        
        print("PEOPLE SELECTED COUNT: \(peopleListSelected.count)")
        // Check the number of people selected
        if peopleListSelected.count > 0 {
            if let parentVC = self.blobAddPeopleDelegate {
                parentVC.selectedPerson()
            }
        } else {
            if let parentVC = self.blobAddPeopleDelegate {
                parentVC.deselectedAllPeople()
            }
        }
        
        // SELECTED PEOPLE CHECK
        for person in peopleListSelected {
            print("PERSON SELECTED: \(person.userName)")
        }
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        print("DID HIGHLIGHT ROW: \((indexPath as NSIndexPath).row)")
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        print("DID UNHIGHLIGHT ROW: \((indexPath as NSIndexPath).row)")
    }
    
    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    
    // MARK:  UISearchBarDelegate protocol
    
    // Edit the peopleList based on the search text filter
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("BAPVC - Search Text: \(searchText)")
        
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
                if userObject.userName.lowercased().contains(searchText.lowercased()) {
                    print("BAPVC - UserName Contains: \(searchText)")
                    
                    self.peopleListUse.append(userObject)
                }
            }
        }
        
        // Refresh the Table
        refreshTableAndHighlights()
    }
    
    
    // MARK: GESTURE METHODS
    
    func tapSelectAll(_ gesture: UIGestureRecognizer) {
        if selectAll {
            selectAll = false
            selectAllBox.text = ""
            selectAllMessage.removeFromSuperview()
            searchBarContainer.addSubview(searchBar)
            
            if let parentVC = self.blobAddPeopleDelegate {
                parentVC.changeMapCircleType(Constants.BlobTypes.temporary)
            }
            
            // Toggle the Send button
            if let parentVC = self.blobAddPeopleDelegate {
                parentVC.deselectedAllPeople()
            }
            
        } else {
            selectAll = true
            selectAllBox.text = "\u{2713}"
            viewContainer.addSubview(selectAllMessage)
            searchBar.removeFromSuperview()
            
            if let parentVC = self.blobAddPeopleDelegate {
                parentVC.changeMapCircleType(Constants.BlobTypes.public)
            }
            
            // Toggle the Send button
            if let parentVC = self.blobAddPeopleDelegate {
                parentVC.selectedPerson()
            }
        }
    }
    
    
    // MARK: CUSTOM FUNCTIONS
    
    // Refresh the collectionView and highlight any users that were previously highlighted
    func refreshTableAndHighlights() {
        
        // Reload the Table View
        print("BAPVC - REFRESH TABLE AND HIGHLIGHTS - RELOAD TABLE VIEW")
        self.peopleTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
        
        // Loop through the Selected People list and highlight the associated people in the Use People list
        for selectedPerson in peopleListSelected {
            loopUsePeopleList: for (useIndex, usePerson) in self.peopleListUse.enumerated() {
                if usePerson.userID == selectedPerson.userID {
                    
                    // Highlight that person in the table view
                    self.peopleTableView.selectRow(at: IndexPath(row: useIndex, section: 0), animated: false, scrollPosition: UITableViewScrollPosition.none)
                    break loopUsePeopleList
                }
            }
        }
    }
    
    // Create a solid color UIImage
    func getImageWithColor(_ color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    
    // MARK: AWS FUNCTIONS
    
    // The initial request for Map Blob data - called when the View Controller is instantiated
    func getUserConnections() {
        print("BAPVC - REQUESTING GUC")
        
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["user_id" : Constants.Data.currentUser, "print_check" : "BAP"]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-GetUserConnections", jsonObject: json, completionHandler: { (response, err) -> Void in
            
            if (err != nil) {
                print("BAPVC - GET USER CONNECTIONS DATA ERROR: \(err)")
            } else if (response != nil) {
                
                // Convert the response to an array of arrays
                if let userConnectionArrays = response as? [[AnyObject]] {
                    
                    // Loop through the arrays and add each user - the arrays should be in the proper order by user type
                    for (arrayIndex, userArray) in userConnectionArrays.enumerated() {
                        print("BAPVC - array: \(arrayIndex): jsonData: \(userArray)")
                        print("BAPVC - USER COUNT: \(userArray.count)")
                        
                        // Stop the table loading spinner before adding data so that it does not show up in front of the user list
                        //                        self.accountTableActivityIndicator.stopAnimating()
                        
                        // Loop through each AnyObject (User) in the array
                        for user in userArray {
                            print("BAPVC - USER: \(user)")
                            
                            // Convert the AnyObject to JSON with keys and AnyObject values
                            // Then convert the AnyObject values to Strings or Numbers depending on their key
                            if let checkUser = user as? [String: AnyObject] {
                                let userID = checkUser["user_id"] as! String
                                let userName = checkUser["user_name"] as! String
                                let userImageKey = checkUser["user_image_key"] as! String
                                print("BAPVC - USER ID: \(userID)")
                                print("BAPVC - USER NAME: \(userName)")
                                print("BAPVC - USER IMAGE KEY: \(userImageKey)")
                                
                                // Create a User Object and add it to the global User array
                                let addUser = User()
                                addUser.userID = userID
                                addUser.userName = userName
                                addUser.userImageKey = userImageKey
                                addUser.userStatus = Constants.UserStatusTypes(rawValue: arrayIndex)
                                
                                print("BAPVC - TRYING TO ADD DOWNLOADED USER: \(userName)")
                                
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
                                    if addUser.userStatus == Constants.UserStatusTypes.connected {
                                        self.peopleList.append(addUser)
                                        print("BAPVC - ADDED CONNECTED USER \(addUser.userName) TO PEOPLE LIST")
                                    }
                                }
                                print("BAPVC - PEOPLE LIST COUNT: \(self.peopleList.count)")
                            }
                        }
                    }
                    
                    // Sort the list alphabetically and copy the peopleList to the peopleList to use in the table
                    self.peopleList.sort(by: {$0.userName <  $1.userName})
                    self.peopleListUse = self.peopleList
                    
                    // Reload the Table View
                    self.refreshTableAndHighlights()
                }
            }
        })
    }
    
    // Download User Image
    func getUserImage(_ userID: String, imageKey: String) {
        print("BAPVC - GETTING IMAGE FOR: \(imageKey)")
        
        let downloadingFilePath = NSTemporaryDirectory() + imageKey // + Constants.Settings.frameImageFileType)
        let downloadingFileURL = URL(fileURLWithPath: downloadingFilePath)
        let transferManager = AWSS3TransferManager.default()
        
        // Download the Frame
        let downloadRequest : AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.bucket = Constants.Strings.S3BucketUserImages
        downloadRequest.key =  imageKey
        downloadRequest.downloadingFileURL = downloadingFileURL
        
        transferManager?.download(downloadRequest).continue({ (task) -> AnyObject! in
            if let error = task.error {
                if error._domain == AWSS3TransferManagerErrorDomain as String
                    && AWSS3TransferManagerErrorType(rawValue: error._code) == AWSS3TransferManagerErrorType.paused {
                    print("BAPVC - DOWNLOAD PAUSED")
                } else {
                    print("BAPVC - DOWNLOAD FAILED: [\(error)]")
                }
            } else if let exception = task.exception {
                print("BAPVC - DOWNLOAD FAILED: [\(exception)]")
            } else {
                print("BAPVC - DOWNLOAD SUCCEEDED")
                DispatchQueue.main.async(execute: { () -> Void in
                    // Assign the image to the Preview Image View
                    if FileManager().fileExists(atPath: downloadingFilePath) {
                        print("BAPVC - IMAGE FILE AVAILABLE")
                        let thumbnailData = try? Data(contentsOf: URL(fileURLWithPath: downloadingFilePath))
                        
                        // Ensure the Thumbnail Data is not null
                        if let tData = thumbnailData {
                            print("BAPVC - GET IMAGE - CHECK 1")
                            
                            // Find the correct User Object in the local list and assign the newly downloaded Image
                            loopUserObjectCheckLocal: for userObjectLocal in self.peopleList {
                                if userObjectLocal.userID == userID {
                                    userObjectLocal.userImage = UIImage(data: tData)
                                    
                                    break loopUserObjectCheckLocal
                                }
                            }
                            
                            print("BAPVC - ADDED IMAGE: \(imageKey))")
                            
                            // Reload the Table View
                            self.refreshTableAndHighlights()
                        }
                        
                    } else {
                        print("BAPVC - FRAME FILE NOT AVAILABLE")
                    }
                })
            }
            return nil
        })
    }

}
