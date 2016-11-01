//
//  BlobAddMediaViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 7/30/16.
//  Copyright © 2016 tangojlabs. All rights reserved.
//

import AVFoundation
import UIKit


// Create a protocol with functions declared in other View Controllers implementing this protocol (delegate)
protocol BlobAddMediaViewControllerDelegate {
    
    // When called, the parent View Controller instantiates the Media Picker View Controller
    func pickMediaPicker()
}

class BlobAddMediaViewController: UIViewController {
    
    // Add a delegate variable which the parent view controller can pass its own delegate instance to and have access to the protocol
    // (and have its own functions called that are listed in the protocol)
    var blobAddMediaDelegate: BlobAddMediaViewControllerDelegate?
    
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    // Declare the view components
    var viewContainer: UIView!
    var mediaPickerImage: UIImageView!
    var videoPlayIndicator: UILabel!
    
    var mediaPickerTapGesture: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Status Bar Settings
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        viewFrameY = self.view.frame.minY
        screenSize = UIScreen.main.bounds
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height - 74 - self.view.frame.width))
        self.view.addSubview(viewContainer)
        
        mediaPickerImage = UIImageView(frame: CGRect(x: (viewContainer.frame.width / 2) - ((viewContainer.frame.height - 20) / 2), y: 10, width: viewContainer.frame.height - 20, height: viewContainer.frame.height - 20))
        mediaPickerImage.contentMode = UIViewContentMode.scaleAspectFill
        mediaPickerImage.clipsToBounds = true
        mediaPickerImage.image = UIImage(named: Constants.Strings.iconStringDefaultMedia)
        viewContainer.addSubview(mediaPickerImage)
        
        videoPlayIndicator = UILabel(frame: CGRect(x: 5, y: 5, width: 25, height: 25))
        videoPlayIndicator.text = ""
        videoPlayIndicator.textColor = UIColor.white
        videoPlayIndicator.textAlignment = .center
        videoPlayIndicator.font = UIFont(name: Constants.Strings.fontRegular, size: 18)
        mediaPickerImage.addSubview(videoPlayIndicator)
        
        mediaPickerTapGesture = UITapGestureRecognizer(target: self, action: #selector(BlobAddMediaViewController.showMediaPicker(_:)))
        mediaPickerTapGesture.numberOfTapsRequired = 1  // add single tap
        viewContainer.addGestureRecognizer(mediaPickerTapGesture)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: GESTURE RECOGNIZERS
    
    func showMediaPicker(_ gesture: UITapGestureRecognizer) {
        
        if let parentVC = self.blobAddMediaDelegate {
            print("CALLING PARENT DELEGATE")
            parentVC.pickMediaPicker()
        }
    }

    
    // MARK: - Navigation

    

}
