//
//  WebToolBarView.swift
//  Revo
//
//  Created by Waylan Sands on 27/1/21.
//

import UIKit

protocol WebToolBarDelegate: class {
    func webRecordingButtonPress()
    func toggleRecodingMode()
    func goBackwardsAPage()
    func goForwardAPage()
    func visitLibrary()
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

    // The Recoding button for the web view
    let recordingButton = WebRecordButtonView()
    
    weak var delegate: WebToolBarDelegate?
    
    let libraryButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.libraryIcon, for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(visitLibraryVC), for: .touchUpInside)
        button.layer.borderWidth = 3
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        button.clipsToBounds = true
        return button
    }()
    
    private let recordingModeButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(toggleCameraMode), for: .touchUpInside)
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
        self.addGestureRecogniser()
        self.configureViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func addGestureRecogniser() {
        recordingButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(recordingButtonPress)))
    }
    
    private func configureViews() {
        self.addSubview(libraryButton)
        libraryButton.translatesAutoresizingMaskIntoConstraints = false
        libraryButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 20).isActive = true
        libraryButton.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 20).isActive = true
        libraryButton.widthAnchor.constraint(equalToConstant: 45).isActive = true
        libraryButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
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
    
    func updateLibraryButtonThumbnail() {
        if let fileURL = FileManager.lastFileAddedToDirectory() {
            let image = UIImage.thumbnailFromMovie(url: fileURL)
            DispatchQueue.main.async {
                self.libraryButton.setImage(image, for: .normal)
                self.libraryButton.layer.borderColor = UIColor.white.cgColor
            }
        } else {
            libraryButton.setImage(RevoImages.libraryIcon, for: .normal)
            self.libraryButton.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    @objc func visitLibraryVC() {
        if recordingButton.currentState == .recording {
            Alert.showBasicAlert(title: "Currently Recording", message: "You're currently in a recording session, stop the session first if you visit the library", vc: delegate as! UIViewController)
        } else {
            delegate?.visitLibrary()
        }
    }
    
    @objc func recordingButtonPress() {
        delegate?.webRecordingButtonPress()
    }
    
    @objc func toggleCameraMode() {
        if recordingButton.currentState == .recording {
            Alert.showBasicAlert(title: "Currently Recording", message: "You're currently in a recording session, stop the session first if you would like to change recording mode", vc: delegate as! UIViewController)
            return
        }
        
        switch recordingMode {
        case .live:
            recordingButton.recordingMode = .video
            delegate?.toggleRecodingMode()
            recordingMode = .video
        case .video:
            recordingButton.recordingMode = .live
            delegate?.toggleRecodingMode()
            checkIfUserIsAwareOfLiveMode()
            recordingMode = .live
        }
    }
    
    func updateForCamera(mode: RecordingMode) {
        switch mode {
        case .live:
            recordingButton.recordingMode = .live
            recordingMode = .live
        case .video:
            recordingButton.recordingMode = .video
            recordingMode = .video
        }
        
    }
    
    private func checkIfUserIsAwareOfLiveMode() {
        let userIsAware = UserDefaults.standard.bool(forKey: "userIsAwareOfLiveMode")
        // Make sure that the user has not seen this message before
        if !userIsAware {
            Alert.showBasicAlert(title: "Live Broadcasting".localized, message: "live_broadcasting_message".localized, vc: delegate as! UIViewController)
            UserDefaults.standard.setValue(true, forKey: "userIsAwareOfLiveMode")
        }
    }
    
    @objc func goBack() {
        delegate?.goBackwardsAPage()
    }
    
    @objc func goForward() {
        delegate?.goForwardAPage()
    }
    
}

