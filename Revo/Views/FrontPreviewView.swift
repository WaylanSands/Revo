//
//  FrontFramePreviewView.swift
//  Revo
//
//  Created by Waylan Sands on 3/12/20.
//

import UIKit
import Foundation
import AVFoundation

enum FrameStyle {
    case circular
    case square
}

class FrontPreviewView: UIView {
    
    enum EditingMode {
        case editing
        case ready
    }

    private lazy var lastYPosition: CGFloat = self.center.y - 100
    private lazy var lastXPosition: CGFloat = self.center.x - 100
        
    private var lastSize: CGFloat = 200
    
    private  var frameStyle: FrameStyle = .square {
        didSet {
            if frameStyle == .circular {
                self.layer.cornerRadius = self.frame.width / 2
            } else {
                self.layer.cornerRadius = 10
            }
        }
    }
    
    var editingMode: EditingMode = .ready

    override init(frame: CGRect) {
        super.init(frame: CGRect(x: UIScreen.main.bounds.width - 220, y: 100, width: 200, height: 200))
        self.layer.borderColor = UIColor.white.cgColor
        self.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(trackPanning)))
        self.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinching)))
        self.isUserInteractionEnabled = true
        self.layer.cornerRadius = 10
        self.layer.borderWidth = 5
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    @objc private func editFramePreview() {
        switch editingMode {
        case .ready:
            editingMode = .editing
        case .editing:
            editingMode = .ready
        }
    }
    
    @objc private func trackPanning(gestureRecognizer: UIPanGestureRecognizer) {
                
        let position = gestureRecognizer.translation(in: superview)
    
        self.frame.origin.y = position.y + lastYPosition
        self.frame.origin.x = position.x + lastXPosition

        switch gestureRecognizer.state {
        case .began:
            break
        case .changed:
            break
        case .cancelled:
            break
        case .ended:
            lastYPosition = self.frame.origin.y
            lastXPosition = self.frame.origin.x
            checkIfOutOfView()
        default:
            break
        }
        
    }
    
    // Check if the view's frame is outside of MainRecordingVC's view if so
    // it will bump it back into frame via an animation.
    private func checkIfOutOfView() {
        if lastYPosition < 0 {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: bumpDown, completion: nil)
        } else if lastYPosition > UIScreen.main.bounds.height - self.frame.height {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: bumpUp, completion: nil)
        }
    }
    
    private func bumpDown() {
        self.frame.origin.y = 90
        lastYPosition = self.frame.origin.y
    }
    
    private func bumpUp() {
        self.frame.origin.y = UIScreen.main.bounds.height - 30 - self.frame.height
        lastYPosition = self.frame.origin.y
    }
    
    @objc private func pinching(gestureRecognizer: UIPinchGestureRecognizer) {
        
        let scale = gestureRecognizer.scale
        self.frame.size = CGSize(width: lastSize * scale, height: lastSize * scale)
        
        switch gestureRecognizer.state {
        case .began:
            break
        case .changed:
            if frameStyle == .circular {
                self.layer.cornerRadius = self.frame.width / 2
            } else {
                self.layer.cornerRadius = 10
            }
        case .cancelled:
            break
        case .ended:
            lastSize = self.frame.width
            checkIfOutOfView()
        default:
            break
        }
    }
    
}

extension FrontPreviewView: PipModeStyleDelegate {
    
    func updateStyleWith(style: FrameStyle, borderWidth: CGFloat, color: UIColor) {
        layer.borderColor = color.cgColor
        layer.borderWidth = borderWidth
        frameStyle = style
    }
    

}
