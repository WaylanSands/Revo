//
//  RecordingsSelectedView.swift
//  Revo
//
//  Created by Waylan Sands on 8/12/20.
//

import UIKit

class RecordingOptionsView: UIView {
    
    /// Dynamically set depending on device size
    private var dynamicHeight: CGFloat = 80
    
    let shareButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.shareIcon, for: .normal)
        return button
    }()
    
    let deleteButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.deleteIcon, for: .normal)
        return button
    }()
    
    let optionsLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.isHidden = true
        return label
    }()
    
    let progressView: UIProgressView = {
        let view = UIProgressView()
        view.tintColor = .blue
        view.isHidden = true
        view.sizeToFit()
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
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
        self.addSubview(shareButton)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 20).isActive = true
        shareButton.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 20).isActive = true
        
        self.addSubview(deleteButton)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 20).isActive = true
        deleteButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20).isActive = true
        
        self.addSubview(optionsLabel)
        optionsLabel.translatesAutoresizingMaskIntoConstraints = false
        optionsLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 23).isActive = true
        optionsLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        
        self.addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.bottomAnchor.constraint(equalTo: self.topAnchor).isActive = true
        progressView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive =  true
        progressView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive =  true
    }
    
    func updatePositionTo(state: SelectionState) {
        var yPosition: CGFloat
        switch state {
        case .active:
            // Reveal view
            yPosition = UIScreen.main.bounds.height - dynamicHeight
        case .inactive:
            // Hide view
            yPosition = UIScreen.main.bounds.height
            optionsLabel.isHidden = true
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            self.frame = CGRect(x: 0, y: yPosition, width: UIScreen.main.bounds.width, height: self.dynamicHeight)
        }, completion: nil)
    }
    
    


}
