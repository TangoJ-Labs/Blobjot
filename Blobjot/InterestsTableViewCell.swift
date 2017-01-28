//
//  InterestsTableViewCell.swift
//  Blobjot
//
//  Created by Sean Hart on 1/27/17.
//  Copyright © 2017 blobjot. All rights reserved.
//

import UIKit


class InterestsTableViewCell: UITableViewCell, UIScrollViewDelegate
{
    var IntScroll = UIScrollView()
    var IntRounder = UIView()
    var INT = Int()
    var IntImage = UIImageView()
    var interestLabel = UILabel()
    var selectedLabel = UILabel()
    var deleteLabel = UILabel()
    var addSwitch = UISwitch()
    
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init(coder: decoder)!
    }
    
    override func layoutSubviews()
    {
        self.backgroundColor = UIColor(red: 249.0/255.0, green: 249.0/255.0, blue: 249.0/255.0, alpha: 1.0)
        
        IntScroll.delegate = self
        IntScroll.contentOffset = CGPoint(x:0 , y:0)
        IntScroll.showsVerticalScrollIndicator = false
        IntScroll.showsHorizontalScrollIndicator = false
        IntScroll.isDirectionalLockEnabled = true
        IntScroll.isPagingEnabled = true
        IntScroll.bounces = true
        IntScroll.backgroundColor = UIColor.white
        IntScroll.clipsToBounds = true
        IntScroll.frame = CGRect.init(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height - 6)
        IntScroll.contentSize = CGSize.init(width: self.bounds.width * 1.3 , height: self.bounds.height - 6)
        
        IntImage.frame = CGRect.init(x: self.bounds.width * 0.05, y: self.bounds.height * 0.15, width: self.bounds.height * 0.5, height: self.bounds.height * 0.5)
        IntImage.layer.cornerRadius = IntImage.bounds.height * 0.5
        IntImage.contentMode = .scaleAspectFill
        IntImage.clipsToBounds = true
        
        if INT == 0
        {
            IntRounder.frame = CGRect.init(x: self.bounds.width * 0.07, y: self.bounds.height * 0.15, width: self.bounds.height * 0.5, height: self.bounds.height * 0.5)
            self.addSwitch.isOn = false
        }
        
        
        if INT == 1
        {
            IntRounder.frame = CGRect.init(x: self.bounds.width * 0.03, y: self.bounds.height * 0.15, width: self.bounds.height * 0.5, height: self.bounds.height * 0.5)
            selectedLabel.text = "added to blob searches"
            self.addSwitch.isOn = true
        }
        
        IntRounder.layer.cornerRadius = IntImage.bounds.height * 0.5
        IntRounder.clipsToBounds = true
        
        interestLabel.frame = CGRect.init(x: self.bounds.width * 0.25, y: self.bounds.height * 0.15, width: self.bounds.width * 0.7, height: self.bounds.height * 0.5 )
        interestLabel.textAlignment = .left
        
        deleteLabel.frame = CGRect.init(x: self.bounds.width , y: 0, width: self.bounds.width * 0.3 , height: self.bounds.height - 1)
        deleteLabel.backgroundColor = UIColor(red: 250.0/255.0, green: 250.0/255.0, blue: 250.0/255.0, alpha: 1.0)
        deleteLabel.font = UIFont(name: "AvenirNext-Heavy", size : 20)
        deleteLabel.textColor = UIColor(red: 234.0/255.0, green: 151.0/255.0, blue: 28.0/255.0, alpha: 1.0)
        deleteLabel.textAlignment = .center
        deleteLabel.text = "DELETE"
        
        selectedLabel.frame = CGRect.init(x: self.bounds.width * 0.275, y: self.bounds.height * 0.55, width: self.bounds.width * 0.7, height: self.bounds.height * 0.35 )
        selectedLabel.font = UIFont(name: "AvenirNext-Medium", size : 14)
        selectedLabel.textColor = UIColor.lightGray
        selectedLabel.textAlignment = .left
        
        self.addSwitch.frame.origin.x = self.bounds.width * 0.8
        self.addSwitch.frame.origin.y = self.bounds.height * 0.2
        //  self.addSwitch.tintColor = UIColor.lightGray
        
        self.contentView.addSubview(IntScroll)
        
        // self.IntScroller.addSubview(IntView)
        self.IntScroll.addSubview(IntRounder)
        self.IntScroll.addSubview(IntImage)
        self.IntScroll.addSubview(interestLabel)
        self.IntScroll.addSubview(deleteLabel)
        self.IntScroll.addSubview(selectedLabel)
        self.IntScroll.addSubview(addSwitch)
    }
    
    
    //    var zigzagOne: UIBezierPath {
    //        let trianglePath = UIBezierPath()
    //        trianglePath.move(to: CGPoint(x: 0 , y: 0))     // #1
    //        trianglePath.addLine(to: CGPoint(x: self.bounds.width * 0.8 , y: 0)) // #2
    //        trianglePath.addLine(to: CGPoint(x: self.bounds.width * 0.85 , y: self.bounds.height))
    //
    //        trianglePath.addLine(to: CGPoint(x: 0 , y: self.bounds.height)) // #2
    //
    //
    //
    //        trianglePath.close()
    //        return trianglePath
    //    }
    //
    //    var zigzagTwo: UIBezierPath {
    //        let trianglePath = UIBezierPath()
    //        trianglePath.move(to: CGPoint(x: 0 , y: 0))     // #1
    //        trianglePath.addLine(to: CGPoint(x: self.bounds.width * 0.85 , y: 0)) // #2
    //        trianglePath.addLine(to: CGPoint(x: self.bounds.width * 0.8 , y: self.bounds.height))
    //
    //        trianglePath.addLine(to: CGPoint(x: 0 , y: self.bounds.height)) // #2
    //
    //
    //        trianglePath.close()
    //        return trianglePath
    //    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        if IntScroll.contentOffset.x < 0.5
        {
            IntScroll.bounces = false
        }
        
        if IntScroll.contentOffset.x > 2
        {
            IntScroll.bounces = true
        }
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
    } 
    
}
