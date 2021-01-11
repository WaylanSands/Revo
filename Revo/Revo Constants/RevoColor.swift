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
    
    static let firstColumn = [
        UIColor.fromHex(code: "#FFAB1C"),
        UIColor.fromHex(code: "#28D5FF"),
        UIColor.white,
    ]
    
    static let secondColumn = [
        UIColor.fromHex(code: "#FFD520"),
        UIColor.fromHex(code: "#2869FF"),
        UIColor.fromHex(code: "#9A9A9A"),
    ]
    
    static let thirdColumn = [
        UIColor.fromHex(code: "#F8FF59"),
        UIColor.fromHex(code: "#4728FF"),
        UIColor.fromHex(code: "#4D4D4D"),
    ]
    
    static let forthColumn = [
        UIColor.fromHex(code: "#8AFF19"),
        UIColor.fromHex(code: "#9728FF"),
        UIColor.fromHex(code: "#313131"),
    ]
    
    static let fifthColumn = [
        UIColor.fromHex(code: "#12FF31"),
        UIColor.fromHex(code: "#FF28B0"),
        UIColor.fromHex(code: "#000000"),
    ]

}
