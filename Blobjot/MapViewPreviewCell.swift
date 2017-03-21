//
//  MapViewBlobPreviewTableViewCell.swift
//  Blobjot
//
//  Created by Sean Hart on 12/31/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import UIKit

class MapViewPreviewCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate
{
    var previewCellContainer: UIView!
    var previewSubCVLayout: UICollectionViewFlowLayout!
    var previewSubCollectionView: UICollectionView!
    
    // View controller variables for temporary user settings and view controls
    var imageArray = [UIImage]()
    
    var previewStartingScrollPosition: CGFloat = 0
    var postUserImageOffset: CGFloat = 0
    
    // Set the Preview Time Label Width for use with multiple views
    let previewTimeLabelWidth: CGFloat = 100
    
    // Use the same size as the collection view items for the Preview User Image
    let previewUserImageSize = Constants.Dim.mapViewLocationBlobsCVItemSize
    
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        previewCellContainer = UIView(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height))
        previewCellContainer.backgroundColor = Constants.Colors.standardBackground
        contentView.addSubview(previewCellContainer)
        
        // Add the Collection View Controller for each parent cv cell
        previewSubCVLayout = UICollectionViewFlowLayout()
        previewSubCVLayout.scrollDirection = .horizontal
        previewSubCVLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        previewSubCVLayout.headerReferenceSize = CGSize(width: 0, height: 0)
        previewSubCVLayout.footerReferenceSize = CGSize(width: 0, height: 0)
        previewSubCVLayout.minimumLineSpacing = 0
        previewSubCVLayout.itemSize = CGSize(width: previewCellContainer.frame.width, height: previewCellContainer.frame.height)
        
        previewSubCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: previewCellContainer.frame.width, height: previewCellContainer.frame.height), collectionViewLayout: previewSubCVLayout)
        previewSubCollectionView.dataSource = self
        previewSubCollectionView.delegate = self
        previewSubCollectionView.register(MapViewPreviewSubCell.self, forCellWithReuseIdentifier: Constants.Strings.previewBlobsSubCellReuseIdentifier)
        previewSubCollectionView.backgroundColor = UIColor.clear
        previewSubCollectionView.alwaysBounceHorizontal = false
        previewSubCollectionView.showsHorizontalScrollIndicator = false
        previewCellContainer.addSubview(previewSubCollectionView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: UI COLLECTION VIEW DATA SOURCE PROTOCOL
    
    // Number of cells to make in CollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return 1
    }
    
    // Create cells for CollectionView
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        // Create reference to CollectionView cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.Strings.locationBlobsCellReuseIdentifier, for: indexPath) as! MapViewLocationBlobsCell
        
        return cell
    }
    
    
    // MARK: UI COLLECTION VIEW DELEGATE PROTOCOL
    
    // Cell Selection Blob
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    // Cell Touch Blob
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath)
    {
    }
    
    // Cell Touch Release Blob
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath)
    {
    }
    
    
    // MARK: SCROLL VIEW DELEGATE METHODS
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        print("MVC - SCROLL VIEW: \(scrollView) WILL DECELERATE: \(decelerate)")
        // Snap the cells to each cell to only show one at a time
        // Only fire if the scrollView is not decelerating, otherwise it will fire immediately from scrollViewWillBeginDecelerating
        if !decelerate
        {
            snapToNearestPreviewCell()
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView)
    {
        print("MVC - SCROLL VIEW: \(scrollView) WILL BEGIN DECELERATING")
        // Snap the cells to each cell to only show one at a time
        //        scrollView.setContentOffset(scrollView.contentOffset, animated: true)
        snapToNearestPreviewCell()
    }
    
    
    // CUSTOM METHODS
    
    func snapToNearestPreviewCell()
    {
        print("MVPC - PV - SNAP TO CELL")
        
        // Calculate the scroll position relative to the cells
        let cellWidth = self.previewCellContainer.frame.width
        let positionByCell = previewSubCollectionView.contentOffset.x / cellWidth
        print("MVPC - PV - positionByCell: \(positionByCell)")
        
        // Find the nearest cell - use the previous scroll position to deterime whether the
        // user is scrolling up or down in order to snap in the direction of the scroll
        var nearestCell = positionByCell.rounded(FloatingPointRoundingRule.up)
        if previewSubCollectionView.contentOffset.x - previewStartingScrollPosition < 0
        {
            nearestCell = positionByCell.rounded(FloatingPointRoundingRule.down)
        }
        print("MVPC - PV - nearestCell: \(nearestCell)")
        
        // Ensure that the nearestCell is not greater than or equal to the array length (array is 0-indexed)
        var nearestCellInt = Int(nearestCell)
        if nearestCellInt >= Constants.Data.previewBlobContent.count
        {
            nearestCellInt = Constants.Data.previewBlobContent.count - 1
        }
        // Ensure that nearestCellInt will not be less than 0
        if nearestCellInt < 0
        {
            nearestCellInt = 0
        }
        
        // Save the current cell
        Constants.Data.previewCurrentIndex = nearestCellInt
        
        // Create an indexPath and animate the scroll to the proper cell
        let indexPath = NSIndexPath(item: nearestCellInt, section: 0)
        print("MVPC - PV - SCROLLING TO CELL: \(indexPath.row)")
        print("MVPC - PV - numberOfItems: \(previewSubCollectionView.numberOfItems(inSection: 0))")
        if previewSubCollectionView.numberOfItems(inSection: 0) - 1 >= nearestCellInt
        {
            previewSubCollectionView.scrollToItem(at: indexPath as IndexPath, at: .centeredHorizontally, animated: true)
            
            // Save the current scroll position for the next scroll calculation
            previewStartingScrollPosition = nearestCell * cellWidth
            print("MVPC - PV - NEW STARTING SCROLL POSITION: \(previewStartingScrollPosition)")
        }
    }
}
