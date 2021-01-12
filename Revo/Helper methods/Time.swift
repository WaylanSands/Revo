//
//  Time.swift
//  revo
//
//  Created by Waylan Sands on 11/1/21.
//

import Foundation

class Time {
    
    static func asString(from time: Double) -> String {
        let hours = Int(time) / 60 % 60 % 60
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if time >= 3600 {
            return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format:"%02i:%02i", minutes, seconds)
        }
    }
    
}
