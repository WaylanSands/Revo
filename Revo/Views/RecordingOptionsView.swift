//
//  RecordingsSelectedView.swift
//  Revo
//
//  Created by Waylan Sands on 8/12/20.
//

import UIKit

class RecordingOptionsView: UIView {
    
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
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        self.configureViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func configureViews() {
        self.addSubview(shareButton)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 20).isActive = true
        shareButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20).isActive = true
        
        self.addSubview(deleteButton)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 20).isActive = true
        deleteButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20).isActive = true
        
        
        self.addSubview(optionsLabel)
        optionsLabel.translatesAutoresizingMaskIntoConstraints = false
        optionsLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 23).isActive = true
        optionsLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    }
    
    func updatePositionTo(state: SelectionState) {
        var yPosition: CGFloat
        switch state {
        case .active:
            // Reveal view
            yPosition = UIScreen.main.bounds.height - 80
        case .inactive:
            // Hide view
            yPosition = UIScreen.main.bounds.height
            optionsLabel.isHidden = true
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            self.frame = CGRect(x: 0, y: yPosition, width: UIScreen.main.bounds.width, height: 80)
        }, completion: nil)
    }
    
    


}
