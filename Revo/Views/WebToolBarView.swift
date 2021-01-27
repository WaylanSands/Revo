//
//  WebToolBarView.swift
//  Revo
//
//  Created by Waylan Sands on 27/1/21.
//

import UIKit

protocol WebToolBarDelegate: class {
    func goBackwardsAPage()
    func goForwardAPage()
}

class WebToolBarView: UIView {
    
    var recordingMode: RecordingMode = .video {
        didSet {
            switch recordingMode {
            case .video:
                recordingModeButton.setImage(RevoImages.cameraIcon(), for: .normal)
            case .live:
                recordingModeButton.setImage(RevoImages.liveButtonIcon, for: .normal)
            }
        }
    }

    private let recordingButton = WebRecordButtonView()
    weak var delegate: WebToolBarDelegate?
    
    private let libraryButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.libraryIcon, for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(visitLibraryVC), for: .touchUpInside)
        button.clipsToBounds = true
        return button
    }()
    
    private let recordingModeButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(cameraMode), for: .touchUpInside)
        button.setImage(RevoImages.cameraIcon(), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    private let backButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.backWebButton, for: .normal)
        button.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        return button
    }()
    
    private let forwardButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.forwardWebButton, for: .normal)
        button.addTarget(self, action: #selector(goForward), for: .touchUpInside)
        return button
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        self.configureViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func configureViews() {
        self.addSubview(libraryButton)
        libraryButton.translatesAutoresizingMaskIntoConstraints = false
        libraryButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 20).isActive = true
        libraryButton.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 20).isActive = true
        libraryButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        libraryButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        self.addSubview(recordingModeButton)
        recordingModeButton.translatesAutoresizingMaskIntoConstraints = false
        recordingModeButton.centerYAnchor.constraint(equalTo: libraryButton.centerYAnchor).isActive = true
        recordingModeButton.leftAnchor.constraint(equalTo: libraryButton.rightAnchor, constant: 25).isActive = true
        recordingModeButton.widthAnchor.constraint(equalToConstant: 48).isActive = true
        
        self.addSubview(recordingButton)
        recordingButton.translatesAutoresizingMaskIntoConstraints = false
        recordingButton.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        recordingButton.centerYAnchor.constraint(equalTo: libraryButton.centerYAnchor).isActive = true
        recordingButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        recordingButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        
        self.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.leftAnchor.constraint(equalTo: recordingButton.rightAnchor, constant: 25).isActive = true
        backButton.centerYAnchor.constraint(equalTo: libraryButton.centerYAnchor).isActive = true
        backButton.widthAnchor.constraint(equalToConstant: 50).isActive = true

        self.addSubview(forwardButton)
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        forwardButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20).isActive = true
        forwardButton.centerYAnchor.constraint(equalTo: libraryButton.centerYAnchor).isActive = true
        forwardButton.widthAnchor.constraint(equalToConstant: 50).isActive = true

    }
    
    @objc func visitLibraryVC() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "visitLibrary"), object: nil)
    }
    
    @objc func recordPress() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "recordScreen"), object: nil)
    }
    
    @objc func cameraMode() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "toggleCameraMode"), object: nil)
        switch recordingMode {
        case .live:
            recordingButton.recordingMode = .video
            recordingMode = .video
        case .video:
//            checkIfUserIsAwareOfLiveMode()
            recordingButton.recordingMode = .live
            recordingMode = .live
        }
    }
    
    @objc func goBack() {
        delegate?.goBackwardsAPage()
    }
    
    @objc func goForward() {
        delegate?.goForwardAPage()
    }
    
}

