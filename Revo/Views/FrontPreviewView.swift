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
    
    var editingMode: EditingMode = .ready

    private lazy var lastYPosition: CGFloat = self.center.y - 100
    private lazy var lastXPosition: CGFloat = self.center.x - 100
        
    private var borderWidth: CGFloat = 4.0
    private var lastSize: CGFloat = 200
    
    private var previewBottomConstraint: NSLayoutConstraint!
    private var previewRightConstraint: NSLayoutConstraint!
    private var previewLeftConstraint: NSLayoutConstraint!
    private var previewTopConstraint: NSLayoutConstraint!
    
    let preview = PreviewView()
    
    var frameStyle: FrameStyle = .square {
        didSet {
            if frameStyle == .circular {
                self.preview.layer.cornerRadius = (self.frame.width - (borderWidth * 2)) / 2
                self.layer.cornerRadius = self.frame.width / 2
            } else {
                self.preview.layer.cornerRadius = 10
                self.layer.cornerRadius = 13
            }
        }
    }
    
    override init(frame: CGRect) {
        if UIScreen.main.nativeBounds.height > 1334 {
            super.init(frame: CGRect(x: UIScreen.main.bounds.width - 220, y: 100, width: 200, height: 200))
            lastSize = 200
        } else {
            // Device is an iPhone SE, 6S, 7 , 8 or smaller
            super.init(frame: CGRect(x: UIScreen.main.bounds.width - 200, y: 80, width: 160, height: 160))
            lastSize = 160
        }
        
        self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(trackPanning)))
        self.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinching)))
        self.isUserInteractionEnabled = true
        self.backgroundColor = .white
        self.layer.cornerRadius = 13
        configurePreview()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configurePreview() {
        self.addSubview(preview)
        preview.translatesAutoresizingMaskIntoConstraints = false
        previewBottomConstraint = preview.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4)
        previewRightConstraint = preview.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -4)
        previewLeftConstraint = preview.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 4)
        previewTopConstraint = preview.topAnchor.constraint(equalTo: self.topAnchor, constant: 4)
        preview.layer.cornerRadius = 10

        NSLayoutConstraint.activate([
            previewBottomConstraint,
            previewRightConstraint,
            previewLeftConstraint,
            previewTopConstraint
        ])
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
                self.preview.layer.cornerRadius = (self.frame.width - (borderWidth * 2)) / 2
                self.layer.cornerRadius = self.frame.width / 2
            } else {
                self.preview.layer.cornerRadius = 10
                self.layer.cornerRadius = 13
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
        self.lastSize += borderWidth * 2
        self.borderWidth = borderWidth
        self.backgroundColor = color

        self.frame = CGRect(x: lastXPosition, y: lastYPosition, width: lastSize, height: lastSize)
        
        previewBottomConstraint.constant = -borderWidth
        previewRightConstraint.constant = -borderWidth
        previewLeftConstraint.constant = borderWidth
        previewTopConstraint.constant = borderWidth
        
        frameStyle = style
    }

}
