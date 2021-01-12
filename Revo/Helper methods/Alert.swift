//
//  Alert.swift
//  revo
//
//  Created by Waylan Sands on 11/1/21.
//

import UIKit

class Alert {
    
    /// For showing simple UIAlertController messages. Primarily used for error handling.
   static func showBasicAlert(title: String, message: String, vc: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true, completion: nil)
    }
    
    static func showBlockingAlert(title: String, message: String, vc: UIViewController) {
         let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
         vc.present(alert, animated: true, completion: nil)
     }
    
}
