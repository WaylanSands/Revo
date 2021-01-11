//
//  SplitBarView.swift
//  Revo
//
//  Created by Waylan Sands on 2/12/20.
//

import UIKit

/// A view which sits between the videoPreviewLayer's in splitScreen mode
/// This view acts as a separator that can also pan with users touch changing
/// the size of the SplitScreenVC's videoPreviewLayers.

class SplitBarView: UIView {

    let gestureRecognizer = UIPanGestureRecognizer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addGestureRecognizer(gestureRecognizer)
        self.isUserInteractionEnabled = true
        self.backgroundColor = .black
    }
    
    // For extending panning touches
    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extendedBounds = bounds.insetBy(dx: -10, dy: -10)
        return extendedBounds.contains(point)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}

