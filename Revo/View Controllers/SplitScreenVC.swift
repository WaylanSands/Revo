//
//  SplitScreenViewController.swift
//  Revo
//
//  Created by Waylan Sands on 2/12/20.
//

import UIKit
import AVFoundation

class SplitScreenVC: UIViewController {
    
    // View which divides the videoPreviewLayers
    private let splitBarView = SplitBarView()
    
    // These are interchanged when user switches previews
    var bottomPreviewView = PreviewView()
    var topPreviewView = PreviewView()
    
    private lazy var lastPosition: CGFloat = view.center.y
    
    private let captureSession = AVCaptureSession()
    private var backCameraDataOutput = AVCaptureVideoDataOutput()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }
    
    private func configureViews() {
        view.addSubview(topPreviewView)
        topPreviewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        topPreviewView.videoPreviewLayer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height / 2)
        topPreviewView.backgroundColor = .black
        
        view.addSubview(bottomPreviewView)
        bottomPreviewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        bottomPreviewView.videoPreviewLayer.frame = CGRect(x: 0, y: view.frame.height / 2, width: view.frame.width, height: view.frame.height / 2)
        bottomPreviewView.backgroundColor = .black
        
        view.addSubview(splitBarView)
        splitBarView.frame = CGRect(x: 0, y: view.center.y - 2, width: view.frame.width, height: 4)
        splitBarView.gestureRecognizer.addTarget(self, action: #selector(splitViewSlide))
    }
        
    // Allows the user to change the height of the videoPreviewLayers by panning the splitBarView.
    @objc private func splitViewSlide(gestureRecognizer: UIPanGestureRecognizer)  {
        let bottomHeight = view.frame.height - splitBarView.frame.origin.y
        let position = gestureRecognizer.translation(in: view)
        splitBarView.frame.origin.y = position.y + (lastPosition - 2)
        
        topPreviewView.videoPreviewLayer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: position.y + lastPosition)
        bottomPreviewView.videoPreviewLayer.frame = CGRect(x: 0, y: position.y + lastPosition, width: view.frame.width, height: bottomHeight)
        
        switch gestureRecognizer.state {
        case .ended:
            lastPosition = splitBarView.frame.origin.y
        default:
            break
        }
    }
    
    // Switches the top and bottom videoPreviewLayers
    @objc func switchPreviews() {
        let topPreview = topPreviewView
        let topFrame = topPreviewView.frame
        
        topPreviewView.frame = bottomPreviewView.frame
        topPreviewView = bottomPreviewView
        
        bottomPreviewView.frame = topFrame
        bottomPreviewView = topPreview
    }
    
}

extension SplitScreenVC: SplitModeStyleDelegate {
    
    // Allows user to update the style of the splitBarView
    func updateStyleWith(lineHeight: CGFloat, color: UIColor) {
        splitBarView.frame = CGRect(x: splitBarView.frame.minX, y: splitBarView.frame.minY, width: view.frame.width, height: lineHeight)
        splitBarView.backgroundColor = color
    }
}
