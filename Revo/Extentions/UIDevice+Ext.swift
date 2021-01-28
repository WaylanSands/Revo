//
//  UIDevice+Ext.swift
//  Revo
//
//  Created by Waylan Sands on 28/1/21.
//

import UIKit


extension UIDevice {
    
    enum DeviceType: String {
        case iPhoneSE // SE
        case iPhone8 // 6S, 7 , 8
        case iPhone8Plus  // 6+, 6S+, 7+ , 8+
        case iPhone11  // 11, XR
        case iPhone12Mini // 12 Mini
        case iPhone12 // 12, 12 Pro
        case iPhone11Pro // 11 Pro, X, XS
        case iPhone11ProMax // 11 Pro Max, XS Max
        case iPhone12ProMax // 12ProMax
        case unknown
    }
    
    var deviceType: DeviceType {
        switch UIScreen.main.nativeBounds.height {
        case 1136:
            return .iPhoneSE
        case 1334:
            return .iPhone8
        case 1920, 2208:
            return .iPhone8Plus
        case 1792:
            return .iPhone11
        case 2340:
            return .iPhone12Mini
        case 2532:
            return .iPhone12
        case 2436:
            return .iPhone11Pro
        case 2688:
            return .iPhone11ProMax
        case 2778:
            return .iPhone12ProMax
        default:
            return .unknown
        }
    }
    
    
}
