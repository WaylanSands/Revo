//
//  RevoColor.swift
//  Revo
//
//  Created by Waylan Sands on 4/12/20.
//

import UIKit

struct RevoColor {
    
    static let blackText = UIColor.fromHex(code: "#111111")
    static let recordingRed = UIColor.fromHex(code: "#FF0060")
    static let recordingSelection = #colorLiteral(red: 0, green: 0.3469610214, blue: 0.9959824681, alpha: 1)
    
    // Colour options for user when styling in pipMode or splitScreenMode
    static let colorOptions = [firstColumn, secondColumn, thirdColumn, forthColumn, fifthColumn]
    static let colorButtonSelectionColor = UIColor.fromHex(code: "#3C3C3C").cgColor
    
    static let RevoStyleView = UIColor(named: "RevoStyleView")
    
    static let firstColumn = [
        UIColor.fromHex(code: "#FDE9BA"),
        UIColor.fromHex(code: "#74E190"),
        UIColor.white,
    ]
    
    static let secondColumn = [
        UIColor.fromHex(code: "#FFFB8F"),
        UIColor.fromHex(code: "#A9D9EF"),
        UIColor.fromHex(code: "#FFD3DD"),
    ]
    
    static let thirdColumn = [
        UIColor.fromHex(code: "#FFF400"),
        UIColor.fromHex(code: "#64A2B3"),
        UIColor.fromHex(code: "#FDA99D"),
    ]
    
    static let forthColumn = [
        UIColor.fromHex(code: "#D0E2A3"),
        UIColor.fromHex(code: "#64A7FF"),
        UIColor.fromHex(code: "#FF492D"),
    ]
    
    static let fifthColumn = [
        UIColor.fromHex(code: "#B0D890"),
        UIColor.fromHex(code: "#39A5FF"),
        UIColor.fromHex(code: "#000000"),
    ]

}
