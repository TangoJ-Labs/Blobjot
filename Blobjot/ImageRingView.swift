//
//  ImageRingView.swift
//  Blobjot
//
//  Created by Sean Hart on 2/26/17.
//  Copyright © 2017 blobjot. All rights reserved.
//

import UIKit

class ImageRingView: UIView
{
    var viewFrame : CGRect!
    var circleOffsetX: CGFloat!
    var circleOffsetY: CGFloat!
    var circleRadius: CGFloat!
    
    
    // MARK: - Initialization
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    required init(frame : CGRect, circleOffsetX: CGFloat, circleOffsetY: CGFloat, circleRadius: CGFloat)
    {
        self.viewFrame = frame
        self.circleOffsetX = circleOffsetX
        self.circleOffsetY = circleOffsetY
        self.circleRadius = circleRadius
        
        super.init(frame: frame)
        
        createView()
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
    }
    
    
    // MARK: - Drawing
    
    func createView()
    {
        let overlayView = UIView(frame: frame)
        overlayView.layer.cornerRadius = frame.width / 2
        overlayView.alpha = 0.3
        overlayView.backgroundColor = UIColor.white
        self.addSubview(overlayView)
        
        // Create a path with the rectangle in it.
        let path = CGMutablePath()
        path.addArc(center: CGPoint(x: circleOffsetX, y: circleOffsetY), radius: circleRadius, startAngle: 0.0, endAngle: 2 * 3.14, clockwise: false)
        path.addRect(CGRect(x: 0, y: 0, width: overlayView.frame.width, height: overlayView.frame.height))
        
        let maskLayer = CAShapeLayer()
//        maskLayer.backgroundColor = UIColor.red.cgColor
        maskLayer.path = path
        maskLayer.fillRule = kCAFillRuleEvenOdd
        
        // Release the path since it's not covered by ARC.
        overlayView.layer.mask = maskLayer
        overlayView.clipsToBounds = true
    }
    
    override func layoutSubviews () {
        super.layoutSubviews()
    }
}
