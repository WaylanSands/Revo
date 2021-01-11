//
//  FullScreenPreviewView.swift
//  Revo
//
//  Created by Waylan Sands on 2/12/20.
//

import UIKit
import Foundation
import AVFoundation


class PreviewView: UIView {
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    // Convenience wrapper to get layer as its statically known type.
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
}
