//
//  UIButton+Ext.swift
//  Revo
//
//  Created by Waylan Sands on 6/12/20.
//

import UIKit

extension UIButton {
    
    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extendedBounds = bounds.insetBy(dx: -10, dy: -10)
        return extendedBounds.contains(point)
    }
    
    func addUIBlurEffectWith(effect: UIBlurEffect, cornerRadius: CGFloat = 0) {
        
        let blurView = UIVisualEffectView(effect: effect)
        blurView.layer.cornerRadius = cornerRadius
        blurView.isUserInteractionEnabled = false
        blurView.clipsToBounds = true
        
        self.insertSubview(blurView, at: 0)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        blurView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        blurView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        blurView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        
        if let imageView = self.imageView {
            self.bringSubviewToFront(imageView)
        }
    }
    
}
