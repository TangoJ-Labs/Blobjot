//
//  BlobTypeViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 7/31/16.
//  Copyright © 2016 tangojlabs. All rights reserved.
//

import UIKit

// Create a protocol with functions declared in other View Controllers implementing this protocol (delegate)
protocol BlobAddTypeViewControllerDelegate {
    
    // When called, the parent View Controller changes the type of Blob to add
    func changeMapCircleType(type: Constants.BlobTypes)
}


class BlobAddTypeViewController: UIViewController {
    
    // Add a delegate variable which the parent view controller can pass its own delegate instance to and have access to the protocol
    // (and have its own functions called that are listed in the protocol)
    var blobAddTypeDelegate: BlobAddTypeViewControllerDelegate?
    
    // Declare the view components
    var viewContainer: UIView!
    var typeContainer1: UIView!
    var typeContainer1Label: UILabel!
    var typeContainer1Check: UIView!
    var typeContainer1CheckLabel: UILabel!
    var typeContainer2: UIView!
    var typeContainer2Label: UILabel!
    var typeContainer2Check: UIView!
    var typeContainer2CheckLabel: UILabel!
    var typeContainer3: UIView!
    var typeContainer3Label: UILabel!
    var typeContainer3Check: UIView!
    var typeContainer3CheckLabel: UILabel!
    
    // Declare the tap gesture recognizers
    var checkLabel1TapGesture: UITapGestureRecognizer!
    var checkLabel2TapGesture: UITapGestureRecognizer!
    var checkLabel3TapGesture: UITapGestureRecognizer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the view container to hold all other views (decrease size to match pageViewController)
        viewContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height - 74 - self.view.frame.width))
        self.view.addSubview(viewContainer)
        
        // Separate the page view into three sections, one for each Blob type selection
        // Each section should have a label describing the Blob type and a Circle showing the color of the Blob type
        // with an optional check mark to indicate which type has been selected
        
        // Blob Type 1 Container and Content
        typeContainer1 = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height / 3))
        viewContainer.addSubview(typeContainer1)
        
        typeContainer1Label = UILabel(frame: CGRect(x: 20, y: 0, width: typeContainer1.frame.width * (3/4) - 20, height: typeContainer1.frame.height))
        typeContainer1Label.font = UIFont(name: Constants.Strings.fontRegular, size: 26)
        typeContainer1Label.text = "Single-Use Blob"
        typeContainer1Label.textAlignment = .Left
        typeContainer1Label.textColor = Constants.Colors.colorTextGray
        typeContainer1.addSubview(typeContainer1Label)
        
        typeContainer1Check = UIView(frame: CGRect(x: typeContainer1.frame.width * (3/4), y: (typeContainer1.frame.height / 2) - (Constants.Dim.blobAddTypeCircleSize / 2), width: Constants.Dim.blobAddTypeCircleSize, height: Constants.Dim.blobAddTypeCircleSize))
        typeContainer1Check.layer.cornerRadius = Constants.Dim.blobAddTypeCircleSize / 2
        typeContainer1Check.backgroundColor = Constants.Colors.blobRed
        typeContainer1.addSubview(typeContainer1Check)
        
        typeContainer1CheckLabel = UILabel(frame: CGRect(x: 0, y: 0, width: Constants.Dim.blobAddTypeCircleSize, height: Constants.Dim.blobAddTypeCircleSize))
        typeContainer1CheckLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 26)
        typeContainer1CheckLabel.text = "\u{2713}"
        typeContainer1CheckLabel.textAlignment = .Center
        typeContainer1CheckLabel.textColor = UIColor.whiteColor()
        typeContainer1Check.addSubview(typeContainer1CheckLabel)
        
        // Include a border at the bottom of each container to separate the containers
        let border1 = CALayer()
        border1.frame = CGRect(x: 10, y: typeContainer1.frame.height - 1, width: typeContainer1.frame.width - 20, height: 1)
        border1.backgroundColor = Constants.Colors.blobGray.CGColor
        typeContainer1.layer.addSublayer(border1)
        
        // Blob Type 2 Container and Content
        typeContainer2 = UIView(frame: CGRect(x: 0, y: viewContainer.frame.height / 3, width: viewContainer.frame.width, height: viewContainer.frame.height / 3))
        viewContainer.addSubview(typeContainer2)
        
        typeContainer2Label = UILabel(frame: CGRect(x: 20, y: 0, width: typeContainer2.frame.width * (3/4) - 20, height: typeContainer2.frame.height))
        typeContainer2Label.font = UIFont(name: Constants.Strings.fontRegular, size: 26)
        typeContainer2Label.text = "Permanent Blob"
        typeContainer2Label.textAlignment = .Left
        typeContainer2Label.textColor = Constants.Colors.colorTextGray
        typeContainer2.addSubview(typeContainer2Label)
        
        typeContainer2Check = UIView(frame: CGRect(x: typeContainer2.frame.width * (3/4), y: (typeContainer2.frame.height / 2) - (Constants.Dim.blobAddTypeCircleSize / 2), width: Constants.Dim.blobAddTypeCircleSize, height: Constants.Dim.blobAddTypeCircleSize))
        typeContainer2Check.layer.cornerRadius = Constants.Dim.blobAddTypeCircleSize / 2
        typeContainer2Check.backgroundColor = Constants.Colors.blobYellow
        typeContainer2.addSubview(typeContainer2Check)
        
        typeContainer2CheckLabel = UILabel(frame: CGRect(x: 0, y: 0, width: Constants.Dim.blobAddTypeCircleSize, height: Constants.Dim.blobAddTypeCircleSize))
        typeContainer2CheckLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 26)
        typeContainer2CheckLabel.text = ""
        typeContainer2CheckLabel.textAlignment = .Center
        typeContainer2CheckLabel.textColor = UIColor.whiteColor()
        typeContainer2Check.addSubview(typeContainer2CheckLabel)
        
        let border2 = CALayer()
        border2.frame = CGRect(x: 10, y: typeContainer2.frame.height - 1, width: typeContainer1.frame.width - 20, height: 1)
        border2.backgroundColor = Constants.Colors.blobGray.CGColor
        typeContainer2.layer.addSublayer(border2)
        
        // Blob Type 3 Container and Content
        typeContainer3 = UIView(frame: CGRect(x: 0, y: viewContainer.frame.height * (2/3), width: viewContainer.frame.width, height: viewContainer.frame.height / 3))
        viewContainer.addSubview(typeContainer3)
        
        typeContainer3Label = UILabel(frame: CGRect(x: 20, y: 0, width: typeContainer3.frame.width * (3/4) - 20, height: typeContainer3.frame.height))
        typeContainer3Label.font = UIFont(name: Constants.Strings.fontRegular, size: 26)
        typeContainer3Label.text = "Invisible Blob"
        typeContainer3Label.textAlignment = .Left
        typeContainer3Label.textColor = Constants.Colors.colorTextGray
        typeContainer3.addSubview(typeContainer3Label)
        
        typeContainer3Check = UIView(frame: CGRect(x: typeContainer3.frame.width * (3/4), y: (typeContainer3.frame.height / 2) - (Constants.Dim.blobAddTypeCircleSize / 2), width: Constants.Dim.blobAddTypeCircleSize, height: Constants.Dim.blobAddTypeCircleSize))
        typeContainer3Check.layer.cornerRadius = Constants.Dim.blobAddTypeCircleSize / 2
        typeContainer3Check.backgroundColor = Constants.Colors.blobGray
        typeContainer3.addSubview(typeContainer3Check)
        
        typeContainer3CheckLabel = UILabel(frame: CGRect(x: 0, y: 0, width: Constants.Dim.blobAddTypeCircleSize, height: Constants.Dim.blobAddTypeCircleSize))
        typeContainer3CheckLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 26)
        typeContainer3CheckLabel.text = ""
        typeContainer3CheckLabel.textAlignment = .Center
        typeContainer3CheckLabel.textColor = UIColor.whiteColor()
        typeContainer3Check.addSubview(typeContainer3CheckLabel)
        
        let border3 = CALayer()
        border3.frame = CGRect(x: 10, y: typeContainer3.frame.height - 1, width: typeContainer1.frame.width - 20, height: 1)
        border3.backgroundColor = Constants.Colors.blobGray.CGColor
        typeContainer3.layer.addSublayer(border3)
        
        
        // TAP GESTURE RECOGNIZERS
        
        checkLabel1TapGesture = UITapGestureRecognizer(target: self, action: #selector(BlobAddTypeViewController.tapCheckLabel1(_:)))
        checkLabel1TapGesture.numberOfTapsRequired = 1  // add single tap
        typeContainer1Check.addGestureRecognizer(checkLabel1TapGesture)
        
        checkLabel2TapGesture = UITapGestureRecognizer(target: self, action: #selector(BlobAddTypeViewController.tapCheckLabel2(_:)))
        checkLabel2TapGesture.numberOfTapsRequired = 1  // add single tap
        typeContainer2Check.addGestureRecognizer(checkLabel2TapGesture)
        
        checkLabel3TapGesture = UITapGestureRecognizer(target: self, action: #selector(BlobAddTypeViewController.tapCheckLabel3(_:)))
        checkLabel3TapGesture.numberOfTapsRequired = 1  // add single tap
        typeContainer3Check.addGestureRecognizer(checkLabel3TapGesture)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: GESTURE METHODS
    
    // For a tap on each type of Circle, change the check mark and send the new type to the parent VC
    // The check mark label adjustment is redundant here (also done in "changeMapCircleType", but it is used in case of error with the parent method)
    func tapCheckLabel1(gesture: UIGestureRecognizer) {
        typeContainer1CheckLabel.text = "\u{2713}"
        typeContainer2CheckLabel.text = ""
        typeContainer3CheckLabel.text = ""
        
        if let parentVC = self.blobAddTypeDelegate {
            parentVC.changeMapCircleType(Constants.BlobTypes.Temporary)
        }
    }
    
    func tapCheckLabel2(gesture: UIGestureRecognizer) {
        typeContainer1CheckLabel.text = ""
        typeContainer2CheckLabel.text = "\u{2713}"
        typeContainer3CheckLabel.text = ""
        
        if let parentVC = self.blobAddTypeDelegate {
            parentVC.changeMapCircleType(Constants.BlobTypes.Permanent)
        }
    }
    
    func tapCheckLabel3(gesture: UIGestureRecognizer) {
        typeContainer1CheckLabel.text = ""
        typeContainer2CheckLabel.text = ""
        typeContainer3CheckLabel.text = "\u{2713}"
        
        if let parentVC = self.blobAddTypeDelegate {
            parentVC.changeMapCircleType(Constants.BlobTypes.Invisible)
        }
    }

}
