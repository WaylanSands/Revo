//
//  Bundel+Ext.swift
//  Revo
//
//  Created by Waylan Sands on 3/12/20.
//

import UIKit


extension Bundle {
    
    var applicationName: String {
        if let name = object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            return name
        } else if let name = object(forInfoDictionaryKey: "CFBundleName") as? String {
            return name
        }
        
        return "-"
    }
}


