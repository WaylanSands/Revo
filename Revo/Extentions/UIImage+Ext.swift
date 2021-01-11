//
//  UIImage+Ext.swift
//  Revo
//
//  Created by Waylan Sands on 9/12/20.
//

import UIKit
import AVFoundation


extension UIImage {
    
    /// Returns an optional image created with an AVURLAsset and AVAssetImageGenerator
    static func thumbnailFromMovie(url: URL) -> UIImage? {
        do {
            let asset = AVURLAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            
            return UIImage(cgImage: cgImage)
        } catch {
            print("Error creating thumbnail \(error.localizedDescription)")
            
            return nil
        }
    }
    
}
