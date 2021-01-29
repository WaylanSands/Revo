//
//  TopPreviewOptionsView.swift
//  Revo
//
//  Created by Waylan Sands on 9/12/20.
//

import UIKit

class TopPreviewOptionsView: UIView {
    
    /// Dynamically set depending on device size
    private var dynamicHeight: CGFloat = 80

    let dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    let backButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.whiteBackArrowIcon, for: .normal)
        return button
    }()
    
    let audioButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.audioOnIcon, for: .normal)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        self.configureHeight()
        self.configureViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func configureHeight() {
        if UIScreen.main.nativeBounds.height <= 1334 {
            // Device is an iPhone SE, 6S, 7 , 8 or smaller
            dynamicHeight = 65
        }
    }
    
    private func configureViews() {
        self.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -15).isActive = true
        backButton.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 20).isActive = true
        
        self.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        dateLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -15).isActive = true
        
        self.addSubview(audioButton)
        audioButton.translatesAutoresizingMaskIntoConstraints = false
        audioButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -15).isActive = true
        audioButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20).isActive = true
    }
    
    func updatePositionTo(state: SelectionState) {
        var yPosition: CGFloat
        switch state {
        case .active:
            // Reveal view
            yPosition = 0
        case .inactive:
            // Hide view
            yPosition = -dynamicHeight
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            self.frame = CGRect(x: 0, y: yPosition, width: UIScreen.main.bounds.width, height: self.dynamicHeight)
        }, completion: nil)
    }
    
    func setAudioButtonTo(muted: Bool) {
        if muted {
            audioButton.setImage(RevoImages.audioOffIcon, for: .normal)
        } else {
            audioButton.setImage(RevoImages.audioOnIcon, for: .normal)
        }
    }

}
