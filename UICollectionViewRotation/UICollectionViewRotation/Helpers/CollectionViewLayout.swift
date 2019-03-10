//
//  CollectionViewLayout.swift
//  UICollectionViewRotation
//
//  Created by Oleksandr Lysenkov on 11/15/18.
//  Copyright © 2018 Inventi Labs. All rights reserved.
//

import UIKit


class CollectionViewLayout: UICollectionViewFlowLayout {
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        guard let invalidationContext = context as? UICollectionViewFlowLayoutInvalidationContext, let collectionView = self.collectionView else { return context }
        
        let oldBounds = collectionView.bounds
        
        // MARK: Change the size of content according to the new bounds
        invalidationContext.contentSizeAdjustment = CGSize(width: (newBounds.size.width - oldBounds.size.width) * CGFloat(collectionView.numberOfItems(inSection: 0)), height: newBounds.size.height - oldBounds.size.height)
        invalidationContext.invalidateFlowLayoutDelegateMetrics = oldBounds.size != newBounds.size
        
        // MARK: Keep scroll position on the same element as before the change of bounds
        let oldOffset = collectionView.contentOffset
        let newOffset: CGPoint
        
        if case .vertical = self.scrollDirection, let firstVisibleIndexPath = collectionView.indexPathsForVisibleItems.sorted(by: { $0 < $1 }).first, let flowLayoutDelegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout {
            // MARK: Calculate new vertical offset
            var rowHeights: [Int: CGFloat] = [:]
            var maxRowHeight: CGFloat = 0
            var currentRowWidth: CGFloat = 0
            var currentRow = 0
            
            for row in 0...firstVisibleIndexPath.row {
                let indexPath = IndexPath(row: row, section: firstVisibleIndexPath.section)
                guard let cellSize = flowLayoutDelegate.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) else { continue }
                
                if currentRowWidth + cellSize.width > newBounds.width {
                    // MARK: For multicolumns layout add offset to y only for each new row
                    currentRowWidth = cellSize.width
                    
                    currentRow += 1
                    rowHeights[currentRow] = maxRowHeight
                    maxRowHeight = cellSize.height
                } else {
                    maxRowHeight = max(cellSize.height, maxRowHeight)
                    currentRowWidth += cellSize.width
                }
            }
            
            newOffset = CGPoint(x: oldOffset.x, y: rowHeights.reduce(CGFloat(0), { $0 + $1.value }))
        } else {
            newOffset = CGPoint(x: (oldOffset.x / oldBounds.width) * newBounds.width, y: 0)
        }
        context.contentOffsetAdjustment = CGPoint(x: newOffset.x - oldOffset.x, y: newOffset.y - oldOffset.y)

        return context
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if let oldBounds = self.collectionView?.bounds, oldBounds.size != newBounds.size { return true }
        
        return super.shouldInvalidateLayout(forBoundsChange: newBounds)
    }
}
