//
//  BlobViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 7/28/16.
//  Copyright © 2016 tangojlabs. All rights reserved.
//

import AWSLambda
import AWSS3
import GoogleMaps
import UIKit

class BlobViewController: UIViewController, GMSMapViewDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, AWSRequestDelegate
{
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    // Add the view components
    var viewContainer: UIScrollView!
    var blobContainer: UIView!
    var commentLabelContainer: UIView!
    var commentLabel: UILabel!
//    var commentTableActivityIndicator: UIActivityIndicatorView!
    var commentTableView: UITableView!
    
    // Properties to hold local information
    var scrollViewHeight: CGFloat!
    var tableViewHeightArray = [CGFloat]()
    
    // This blob should be initialized when the ViewController is initialized
    var blob: Blob!
    
    // A property to indicate whether the Blob being viewed was created by the current user
    var userBlob: Bool = false
    
    // A property to indicate whether the Blob has media (whether the comments should automatically be shown or not)
    var blobHasMedia: Bool = false
    
    // An array to hold the comments
    var blobCommentArray = [BlobComment]()

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if blob.blobThumbnailID != nil
        {
            self.blobHasMedia = true
        }
        
        // Device and Status Bar Settings
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        navBarHeight = self.navigationController?.navigationBar.frame.height
        viewFrameY = self.view.frame.minY
        screenSize = UIScreen.main.bounds
        print("BVC - UI SCREEN BOUNDS: \(UIScreen.main.bounds)")
        print("BVC - SCREEN BOUNDS: \(self.view.bounds)")
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        let scrollViewOffset = statusBarHeight + navBarHeight - viewFrameY
        self.scrollViewHeight = self.view.bounds.height - scrollViewOffset
        viewContainer = UIScrollView(frame: CGRect(x: 0, y: scrollViewOffset, width: self.view.bounds.width, height: self.scrollViewHeight))
        viewContainer.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight
        viewContainer.delaysContentTouches = false
        viewContainer.panGestureRecognizer.delaysTouchesBegan = false
        self.view.addSubview(viewContainer)
        
        var blobContainerHeight: CGFloat = self.scrollViewHeight
        if !self.blobHasMedia && !self.userBlob
        {
            blobContainerHeight = viewContainer.frame.height - viewContainer.frame.width
        }
        
        blobContainer = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.bounds.width, height: blobContainerHeight))
        blobContainer.backgroundColor = UIColor.red
        viewContainer.addSubview(blobContainer)
        
        commentLabelContainer = UIView(frame: CGRect(x: 0, y: blobContainerHeight, width: viewContainer.bounds.width, height: 40))
        commentLabelContainer.backgroundColor = UIColor.clear
        viewContainer.addSubview(commentLabelContainer)
        
        commentLabel = UILabel(frame: CGRect(x: 0, y: 0, width: commentLabelContainer.frame.width, height: commentLabelContainer.frame.height))
        commentLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        commentLabel.textColor = Constants.Colors.colorTextGray
        commentLabel.text = "NO COMMENTS YET"
        commentLabel.textAlignment = .center
        commentLabelContainer.addSubview(commentLabel)
        
        let remainingHeight: CGFloat = viewContainer.frame.height - (blobContainerHeight + commentLabelContainer.frame.height)
        var commentTableHeight: CGFloat = 0
        if remainingHeight > 0
        {
            commentTableHeight = remainingHeight
        }
        
//        // Add a loading indicator until the comments have downloaded
//        // Place it behind the top of the tableview, so that the cells block the indicator
//        commentTableActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: blobContainerHeight + commentLabelContainer.frame.height, width: viewContainer.frame.width, height: Constants.Dim.blobViewCommentCellHeight))
//        commentTableActivityIndicator.color = UIColor.black
//        viewContainer.addSubview(commentTableActivityIndicator)
//        
//        // Start animating the activity indicator
//        commentTableActivityIndicator.startAnimating()
//        print("BVC - TABLE INDICATOR START")
        
        // A tableview will hold all comments
        commentTableView = UITableView(frame: CGRect(x: 0, y: blobContainerHeight + commentLabelContainer.frame.height, width: viewContainer.frame.width, height: commentTableHeight))
        commentTableView.dataSource = self
        commentTableView.delegate = self
        commentTableView.register(BlobTableViewCellComment.self, forCellReuseIdentifier: Constants.Strings.blobTableViewCellCommentReuseIdentifier)
        commentTableView.separatorStyle = .none
        commentTableView.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight
        commentTableView.isScrollEnabled = true
        commentTableView.bounces = false
        commentTableView.alwaysBounceVertical = false
        commentTableView.showsVerticalScrollIndicator = false
        commentTableView.isUserInteractionEnabled = true
        commentTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        viewContainer.addSubview(commentTableView)
        
        // Set the scrollview content height - do not include the table height since the comments have not yet downloaded
        viewContainer.contentSize = CGSize(width: viewContainer.frame.width, height: blobContainer.frame.height + commentLabelContainer.frame.height)
        
        // Request the Blob comments
        AWSPrepRequest(requestToCall: AWSGetBlobComments(blobID: self.blob.blobID), delegate: self as AWSRequestDelegate).prepRequest()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: TABLE VIEW DATA SOURCE
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let cellCount = self.blobCommentArray.count
        
        return cellCount
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        let cellHeight = Constants.Dim.blobViewCommentCellHeight
        
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.blobTableViewCellCommentReuseIdentifier, for: indexPath) as! BlobTableViewCellComment
        
        print("BTC - CELL HEIGHT: \(cell.frame.height)")
        
        cell.cellContainer.frame.size.height = Constants.Dim.blobViewCommentCellHeight
        cell.addCommentView.frame.size.height = Constants.Dim.blobViewCommentCellHeight - 4
        
        return cell
    }
    
    // Disable the swipe actions
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print("DID SELECT ROW #\((indexPath as NSIndexPath).item)!")
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
        print("DID DESELECT ROW: \((indexPath as NSIndexPath).row)")
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
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
    
    
    // MARK: SCROLL VIEW DELEGATE METHODS
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        print("BVC - SCROLL VIEW POSITION: \(scrollView.contentOffset.y)")
        
        
    }
    
    
    // MARK: MAPVIEW DELEGATE METHODS
    
    // Called after the map is moved
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition)
    {
        // Adjust the Map Camera back to apply the correct camera angle
        adjustMapViewCamera(mapView)
    }
    
    // Angle the map automatically if the zoom is high enough
    func adjustMapViewCamera(_ mapView: GMSMapView)
    {
        // When not in the add blob process, if the map zoom is 16 or higher, automatically angle the camera
        if mapView.camera.zoom >= 16 && mapView.camera.viewingAngle < 60
        {
            let desiredAngle = Double(60)
            mapView.animate(toViewingAngle: desiredAngle)
            
        }
        else if mapView.camera.zoom < 16 && mapView.camera.viewingAngle > 0
        {
            // Keep the map from being angled if the zoom is too low
            let desiredAngle = Double(0)
            mapView.animate(toViewingAngle: desiredAngle)
        }
    }
    
    
    // MARK: TEXT VIEW DELEGATE METHODS
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
    {
        print("BVC - TEXT VIEW SHOULD BEGIN EDITING")
        
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView)
    {
        print("BVC - TEXT VIEW DID BEGIN EDITING")
    }
    
    
    // MARK: TAP GESTURE METHODS
    
    func blobCommentButtonTap(_ gesture: UITapGestureRecognizer)
    {
    }
    
    
    // MARK: CUSTOM METHODS
    
    func refreshCommentTable()
    {
        print("BVC - REFRESH COMMENT TABLE")
        
        // Reload the TableView
        self.commentTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
        
        let commentLabelNoCommentHeight: CGFloat = 20
        
        if self.blobCommentArray.count > 0
        {
            self.commentLabelContainer.frame.size.height = commentLabelNoCommentHeight
            self.commentLabel.frame.size.height = commentLabelNoCommentHeight
            self.commentLabel.text = ""
        }
        
        // Find the content size of the tableview
        let commentTableContentHeight: CGFloat = tableViewHeight() + commentLabelNoCommentHeight
        
        print("BVC - TABLE CONTENT SIZE: \(commentTableContentHeight)")
        
        // Set the tableview and the scrollview content size to encompass all table rows
//        self.commentTableView.frame.size.height = commentTableContentHeight
        self.commentTableView.frame = CGRect(x: 0, y: blobContainer.frame.height + commentLabelContainer.frame.height, width: viewContainer.frame.width, height: commentTableContentHeight)
        self.viewContainer.contentSize.height = blobContainer.frame.height + commentLabelContainer.frame.height + commentTableContentHeight
    }
    
    func refreshDataManually()
    {
        print("BVC - REFRESH DATA MANUALLY")
        
        // Request the image
        AWSPrepRequest(requestToCall: AWSGetBlobImage(blob: self.blob), delegate: self as AWSRequestDelegate).prepRequest()
        
        // Request the Blob comments
        AWSPrepRequest(requestToCall: AWSGetBlobComments(blobID: self.blob.blobID), delegate: self as AWSRequestDelegate).prepRequest()
    }
    
    func tableViewHeight() -> CGFloat {
        self.commentTableView.layoutIfNeeded()
        
        return self.commentTableView.contentSize.height
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
                case _ as AWSAddBlobView:
                    if !success
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("AWSAddBlobView - Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case let awsGetBlobImage as AWSGetBlobImage:
                    if success
                    {
                        if let blobImage = awsGetBlobImage.blobImage
                        {
                            
                            
                            print("BVC - ADDED IMAGE FOR BLOB WITH TEXT: \(awsGetBlobImage.blob.blobText)")
                        }
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("AWSGetBlobImage - Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case let awsGetBlobComments as AWSGetBlobComments:
                    if success
                    {
                        print("BVC - AWS RETURN - AGBC")
                        
                        self.blobCommentArray = awsGetBlobComments.blobCommentArray
                        
                        // Check to ensure that the user data has been downloaded for each comment's user
                        // If not, download the user data (AWSGetUserImage will be called after AWSGetSingleUserData - so listen for AWSGetUserImage's return)
                        for blobComment in self.blobCommentArray
                        {
                            userLoop: for user in Constants.Data.userObjects
                            {
                                var userExists = false
                                if user.userID == blobComment.userID
                                {
                                    userExists = true
                                    break userLoop
                                }
                                if !userExists
                                {
                                    AWSPrepRequest(requestToCall: AWSGetSingleUserData(userID: blobComment.userID, forPreviewBox: false), delegate: self as AWSRequestDelegate).prepRequest()
                                }
                            }
                        }
                        
                        self.refreshCommentTable()
                        
//                        // Reload the TableView
//                        self.blobTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
//                        
//                        self.refreshControl.endRefreshing()
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("AWSGetBlobComments - Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case _ as AWSGetUserImage:
                    if success
                    {
                        // A new user image was just downloaded for a user in the blob comment list
//                        // Reload the TableView
//                        self.blobTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("AWSGetUserImage - Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                default:
                    print("BVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    // Show the error message
                    let alertController = UtilityFunctions().createAlertOkView("DEFAULT - Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    self.present(alertController, animated: true, completion: nil)
                }
        })
    }

}
