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
    var thumbnail: UIImage?
    var duration: String?
    var isImage = false
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        
        // Check that the file is a movie
        if fileURL.pathExtension != "mov" {
            isImage = true
            thumbnail = UIImage(contentsOfFile: fileURL.absoluteString)
        } else {
            let asset = AVAsset(url: fileURL)
            duration = Time.asString(from: asset.duration.seconds)
            self.thumbnail = UIImage.thumbnailFromMovie(url: fileURL)
        }
    }
    
}
