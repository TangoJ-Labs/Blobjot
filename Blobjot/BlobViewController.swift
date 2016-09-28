//
//  BlobViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 7/28/16.
//  Copyright © 2016 tangojlabs. All rights reserved.
//

import AWSLambda
import AWSS3
import UIKit

class BlobViewController: UIViewController, AWSRequestDelegate {
    
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    // Add the view components
    var viewContainer: UIView!
    var blobCard: UIView!
    var userImageContainer: UIView!
    var userImageView: UIImageView!
    var blobTypeIndicatorView: UIView!
    var blobDatetimeLabel: UILabel!
    var blobDateAgeLabel: UILabel!
    var blobTextView: UITextView!
    var blobImageContainer: UIView!
    var blobImageView: UIImageView!
    
    var blobMediaActivityIndicator: UIActivityIndicatorView!
    
    // This blob should be initialized when the ViewController is initialized
    var blob: Blob!

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.edgesForExtendedLayout = UIRectEdge.None
        
        // Device and Status Bar Settings
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        navBarHeight = self.navigationController?.navigationBar.frame.height
        print("**************** NAV BAR HEIGHT: \(navBarHeight)")
        viewFrameY = self.view.frame.minY
        print("**************** VIEW FRAME Y: \(viewFrameY)")
        screenSize = UIScreen.main.bounds
        print("**************** SCREEN HEIGHT: \(screenSize.height)")
        print("**************** VIEW HEIGHT: \(self.view.frame.height)")

        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: statusBarHeight + navBarHeight - viewFrameY, width: self.view.frame.width, height: self.view.frame.height - statusBarHeight - navBarHeight + viewFrameY))
        viewContainer.backgroundColor = Constants.Colors.blobPurpleOpaque
        self.view.addSubview(viewContainer)
        
        blobCard = UIView(frame: CGRect(x: 5, y: 5, width: viewContainer.frame.width - 10, height: viewContainer.frame.height - 10))
        blobCard.backgroundColor = Constants.Colors.standardBackgroundTransparent
        blobCard.layer.cornerRadius = 5
        blobCard.layer.shadowOffset = CGSize(width: 0, height: 0)
        blobCard.layer.shadowOpacity = 0.5
        blobCard.layer.shadowRadius = 3.0
        viewContainer.addSubview(blobCard)
        
        // The User Image should be in the upper right quadrant
        userImageContainer = UIImageView(frame: CGRect(x: blobCard.frame.width - 5 - Constants.Dim.blobViewUserImageSize, y: 50, width: Constants.Dim.blobViewUserImageSize, height: Constants.Dim.blobViewUserImageSize))
        userImageContainer.layer.cornerRadius = Constants.Dim.blobViewUserImageSize / 2
        userImageContainer.layer.shadowOffset = CGSize(width: 0, height: 0)
        userImageContainer.layer.shadowOpacity = 0.5
        userImageContainer.layer.shadowRadius = 3.0
        blobCard.addSubview(userImageContainer)
        
        userImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: userImageContainer.frame.width, height: userImageContainer.frame.height))
        userImageView.layer.cornerRadius = Constants.Dim.blobViewUserImageSize / 2
        userImageView.contentMode = UIViewContentMode.scaleAspectFill
        userImageView.clipsToBounds = true
        userImageContainer.addSubview(userImageView)
        
        // Try to find the globally stored user data
        loopUserCheck: for user in Constants.Data.userObjects {
            if user.userID == blob.blobUserID {
                
                // If the user image has been downloaded, use the image
                // Otherwise, the image should be downloading currently (requested from the preview box in the Map View)
                // and should be passed to this controller when downloaded
                if let userImage = user.userImage {
                    userImageView.image = userImage
                }
// *COMPLETE******** RECEIVE A NOTIFICATION FROM THE MAP VIEW WHEN THE USER IMAGE HAS BEEN DOWNLOADED (IF NOT ALREADY)
                
                break loopUserCheck
            }
        }
        
        // The Blob Type Indicator should be to the top right of the the User Image
        blobTypeIndicatorView = UIView(frame: CGRect(x: 0 - Constants.Dim.blobViewIndicatorSize / 2, y: 0 - Constants.Dim.blobViewIndicatorSize / 2, width: Constants.Dim.blobViewIndicatorSize, height: Constants.Dim.blobViewIndicatorSize))
        blobTypeIndicatorView.layer.cornerRadius = Constants.Dim.blobViewIndicatorSize / 2
        blobTypeIndicatorView.layer.shadowOffset = CGSize(width: 0, height: 0.2)
        blobTypeIndicatorView.layer.shadowOpacity = 0.2
        blobTypeIndicatorView.layer.shadowRadius = 1.0
        // Ensure blobType is not null
        if let blobType = blob.blobType {
            
            // Assign the Blob Type color to the Blob Indicator
            blobTypeIndicatorView.backgroundColor = Constants().blobColorOpaque(blobType)
        }
        blobCard.addSubview(blobTypeIndicatorView)
        
        // The Datetime Label should be in small font just below the Navigation Bar starting at the left of the screen (left aligned text)
        blobDatetimeLabel = UILabel(frame: CGRect(x: 5, y: 2, width: viewContainer.frame.width / 2 - 5, height: 15))
        blobDatetimeLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 10)
        blobDatetimeLabel.textColor = Constants.Colors.colorTextGray
        blobDatetimeLabel.textAlignment = .left
        blobCard.addSubview(blobDatetimeLabel)
        
        // The Date Age Label should be in small font just below the Navigation Bar at the right of the screen (right aligned text)
        blobDateAgeLabel = UILabel(frame: CGRect(x: viewContainer.frame.width / 2 - 2, y: 2, width: viewContainer.frame.width / 2 - 2, height: 15))
        blobDateAgeLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 10)
        blobDateAgeLabel.textColor = Constants.Colors.colorTextGray
        blobDateAgeLabel.textAlignment = .right
        blobCard.addSubview(blobDateAgeLabel)
        
        if let datetime = blob.blobDatetime {
            let formatter = DateFormatter()
            formatter.dateFormat = "E, H:mm" //"E, MMM d HH:mm"
            let stringDate: String = formatter.string(from: datetime as Date)
            blobDatetimeLabel.text = stringDate
            let stringAge = String(-1 * Int(datetime.timeIntervalSinceNow / 3600)) + " hrs"
            blobDateAgeLabel.text = stringAge
        }
        
        // The Text View should be in the upper left quadrant of the screen (to the left of the User Image), and should extend into the upper right quadrant nearing the User Image
        blobTextView = UITextView(frame: CGRect(x: 5, y: 50, width: viewContainer.frame.width - 15 - Constants.Dim.blobViewUserImageSize, height: viewContainer.frame.height - 60 - viewContainer.frame.width))
        blobTextView.backgroundColor = UIColor.clear
        blobTextView.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        blobTextView.isScrollEnabled = true
        blobTextView.isEditable = false
        blobTextView.isSelectable = false
        if let text = blob.blobText {
            blobTextView.text = text
        }
        blobCard.addSubview(blobTextView)
        
        // The Media Content View should be in the lower half of the screen (partially extending into the upper half)
        // It should span the width of the screen
        // The Image View or the Video Player will be used based on the content (both are the same size, in the same position)
        let blobImageSize = blobCard.frame.width - 10
        blobImageContainer = UIView(frame: CGRect(x: 5, y: blobCard.frame.height - 5 - blobImageSize, width: blobImageSize, height: blobImageSize))
        blobImageContainer.layer.cornerRadius = 5
        blobImageContainer.layer.shadowOffset = CGSize(width: 0, height: 0)
        blobImageContainer.layer.shadowOpacity = 0.5
        blobImageContainer.layer.shadowRadius = 3.0
        blobCard.addSubview(blobImageContainer)
        
        blobImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: blobImageContainer.frame.width, height: blobImageContainer.frame.height))
        blobImageView.layer.cornerRadius = 5
        blobImageView.contentMode = UIViewContentMode.scaleAspectFill
        blobImageView.clipsToBounds = true
        
        // Assign the thumbnail to the image until the real image downloads
        if let thumbnailImage = blob.blobThumbnail {
            blobImageView.image = thumbnailImage
        }
        blobImageContainer.addSubview(blobImageView)
        
        // Add a loading indicator until the Media has downloaded
        // Give it the same size and location as the blobImageView
        blobMediaActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: viewContainer.frame.height - viewContainer.frame.width, width: viewContainer.frame.width, height: viewContainer.frame.width))
        blobMediaActivityIndicator.color = UIColor.black
        blobCard.addSubview(blobMediaActivityIndicator)
        
        // Start animating the activity indicator
        self.blobMediaActivityIndicator.startAnimating()
        
        // Request the image
        AWSPrepRequest(requestToCall: AWSGetBlobImage(blob: self.blob), delegate: self as AWSRequestDelegate).prepRequest()
        
        // RECORD THE VIEW LOCALLY AND IN AWS AND REMOVE THE BLOB LOCALLY IF IT IS NOT A PERMANENT BLOB
        
        // Record that the Blob has been viewed in the local Blob and in the CoreData Blob
        blob.blobViewed = true
// *COMPLETE******* RECORD THE BLOB VIEW IN CORE DATA
        
        // Call the AWS Function and send data to Lambda to record that the use viewed this Blob
        // If this Blob is not permanent, the user will not be able to see the Blob again after closing this view
        AWSPrepRequest(requestToCall: AWSAddBlobView(blobID: blob.blobID, userID: Constants.Data.currentUser), delegate: self as AWSRequestDelegate).prepRequest()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen() {
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
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case let awsGetBlobImage as AWSGetBlobImage:
                    if success
                    {
                        if let blobImage = awsGetBlobImage.blobImage
                        {
                            // Setthe Preview Thumbnail image
                            self.blobImageView.image = blobImage
                            
                            // Stop animating the activity indicator
                            self.blobMediaActivityIndicator.stopAnimating()
                            
                            print("BVC - ADDED IMAGE FOR BLOB WITH TEXT: \(awsGetBlobImage.blob.blobText)")
                        }
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                default:
                    print("DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    // Show the error message
                    let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    self.present(alertController, animated: true, completion: nil)
                }
        })
    }

}
