//
//  BlobAddTextViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 7/30/16.
//  Copyright © 2016 tangojlabs. All rights reserved.
//

import UIKit


// Create a protocol with functions declared in other View Controllers implementing this protocol (delegate)
protocol BlobAddTextViewControllerDelegate
{
    // When called, the parent View Controller checks for content
    func checkContent() -> Bool
}

class BlobAddTextViewController: UIViewController, UITextViewDelegate
{
    // Add a delegate variable which the parent view controller can pass its own delegate instance to and have access to the protocol
    // (and have its own functions called that are listed in the protocol)
    var blobAddTextDelegate: BlobAddTextViewControllerDelegate?
    
    // Declare the view components
    var viewContainer: UIView!
    var textViewContainer: UIView!
    var blobTextView: UITextView!
    var blobTextViewDefaultText: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Add the view container to hold all other views (decrease size to match pageViewController)
        viewContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height - 74 - self.view.frame.width))
        viewContainer.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight
        self.view.addSubview(viewContainer)
        
        // The Blob text view should be centered within the page view and extend the entire width and height, except for a margin
        textViewContainer = UIView(frame: CGRect(x: 5, y: 5, width: viewContainer.frame.width - 10, height: viewContainer.frame.height - 10))
//        textViewContainer.layer.borderWidth = 2.0
//        textViewContainer.layer.borderColor = UIColor.lightGray.cgColor
//        textViewContainer.layer.cornerRadius = 10.0
        viewContainer.addSubview(textViewContainer)
        
        blobTextView = UITextView(frame: CGRect(x: 5, y: 5, width: textViewContainer.frame.width - 10, height: textViewContainer.frame.height - 10))
        blobTextView.backgroundColor = UIColor.white
        blobTextView.delegate = self
        blobTextView.isEditable = true
        blobTextView.isScrollEnabled = true
        blobTextView.font = UIFont(name: Constants.Strings.fontRegular, size: 18)
//        blobTextView.text = "Add a message."
        textViewContainer.addSubview(blobTextView)
        
        blobTextViewDefaultText = UILabel(frame: CGRect(x: 2, y: 5, width: blobTextView.frame.width, height: 20))
        blobTextViewDefaultText.font = UIFont(name: Constants.Strings.fontRegular, size: 18)
        blobTextViewDefaultText.text = "Add a message."
        blobTextView.addSubview(blobTextViewDefaultText)
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
    {
        blobTextViewDefaultText.removeFromSuperview()
        
        if let parentVC = self.blobAddTextDelegate
        {
            _ = parentVC.checkContent()
        }
        
        return true
    }

}
