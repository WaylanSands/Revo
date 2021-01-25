//
//  UIView+Ext.swift
//  Revo
//
//  Created by Waylan Sands on 25/1/21.
//

import UIKit


extension UIView {
    
    static func localizedUIEdgeInsets(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat) -> UIEdgeInsets {

        let layoutDirection = self.userInterfaceLayoutDirection

        if layoutDirection == .leftToRight {
            return UIEdgeInsets(top: top, left: leading, bottom: bottom, right: trailing)
        } else {
            return UIEdgeInsets(top: top, left: trailing, bottom: bottom, right: leading)
        }
    }
    
    static var userInterfaceLayoutDirection: UIUserInterfaceLayoutDirection {
        return UIApplication.shared.userInterfaceLayoutDirection
    }
    
}
