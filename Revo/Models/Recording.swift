//
//  Recording.swift
//  Revo
//
//  Created by Waylan Sands on 8/12/20.
//

import UIKit
import AVFoundation


class Recording {
    
    var fileURL: URL
    var isImage = false
    var duration: String?
    var thumbnail: UIImage?
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        
        if fileURL.pathExtension != "mov" {
            thumbnail = UIImage(contentsOfFile: fileURL.absoluteString)
            isImage = true
        } else {
            let asset = AVAsset(url: fileURL)
            duration = Time.asString(from: asset.duration.seconds)
            self.thumbnail = UIImage.thumbnailFromMovie(url: fileURL)
        }
    }
    
}
