//
//  File.swift
//  Revo
//
//  Created by Waylan Sands on 24/1/21.
//

import UIKit

extension String {
    
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func widthWith(font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: font.lineHeight)
        let boundingBox = self.boundingRect(with: constraintRect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: [.font: font],
                                            context: nil)
        return ceil(boundingBox.width)
    }
    
}
