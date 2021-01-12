//
//  PassThroughWindow.swift
//  Revo
//
//  Created by Waylan Sands on 21/12/20.
//

import UIKit

/// A subclass of UIView that allows touches to fall through to lower views
class PassThroughView: UIView {}


/// Type of UIWindow that allows touches to fall through to lower windows
/// if window contains a PassThroughView & PassThroughView is touched.
class PassThroughWindow: UIWindow {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

        let hitView = super.hitTest(point, with: event)
        
        if hitView!.isKind(of: PassThroughView.self) {
            return nil
        }

        return hitView
    }
}
