//
//  HiddenHUDVC.swift
//  Revo
//
//  Created by Waylan Sands on 16/12/20.
//

import UIKit
import ReplayKit
import FirebaseAnalytics

protocol ControlsDelegate: class {
    func updateCapture(setting: CameraSetting, with slider: UISlider)
    func changePresentationTo(mode: PresentationMode)
    func cameraSelectionOf(selection: CameraSelection)
    func editPreviewStyleFor(mode: PresentationMode)
    func switchPreviewsFor(mode: PresentationMode)
    func changeTorchTo(mode: TorchMode)
}

enum PresentationMode {
    case splitScreen
    case switchCam
    case web
    case pip
}

enum TorchMode {
    case off
    case on
}

enum RecordingMode {
    case video
    case live
}

enum CameraSelection {
    case ultraWide
    case telephoto
    case wide
}

enum CameraSetting {
    case exposure
    case zoom
}

enum DevicesAvailable {
    case builtInDualWideCamera
    case builtInTripleCamera
    case builtInDualCamera
    case single
}

enum EditingState {
    case ready
    case editing
}

class RecordingControlsVC: UIViewController {
    
    // For recording lower UIWindow
    private let screenRecorder = RPScreenRecorder.shared()
    private let broadcastVC = RPBroadcastController()
    
    // Used to write the audio and video buffers
    private let assetWriter = RevoAssetWriter()
    
    private var presentationMode: PresentationMode = .switchCam
    private var torchMode: TorchMode = .off
    
    private var cameraSelection: CameraSelection = .wide
    private var editingMode: EditingState = .ready
    
    private var recordingMode: RecordingMode = .video {
        didSet {
            switch recordingMode {
            case .video:
                recordingButton.recordingMode = .video
            case .live:
                recordingButton.recordingMode = .live
            }
        }
    }
    
    private let settingsVC = SettingsVC()
    
    private var currentSetting: CameraSetting?
    var devicesAvailable = ["1"]
    
    /// Removes setting slider if left dormant
    private var sliderRemovalTimer = Timer()
    private var recordingTime: Timer!
    
    /// The current rear camera ExposureTargetBiasMinMax as an array [min,max]
    var currentCameraExposureTargetBiasMinMax: (() -> ([Float]))?
    var currentCameraExposureTargetBias: (() -> (Float))?
    var currentCameraMaxZoomFactor: (() -> (CGFloat))?
    var currentCameraZoomFactor: (() -> (CGFloat))?
    var alertMultiViewOfRecordingStart: (() -> Void)!
    var alertMultiViewOfRecordingEnd: (() -> Void)!
    
    weak var delegate: ControlsDelegate?
    
    
    // MARK: Record Button
    private let recordingButton = RecordButtonView()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00:00"
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 19, weight: .semibold)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    private let libraryButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.libraryIcon, for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(visitLibraryVC), for: .touchUpInside)
        button.layer.borderWidth = 3
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        return button
    }()
    
    private let recordingModeButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(recordingModePress), for: .touchUpInside)
        button.setImage(RevoImages.cameraIcon(), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    private let settingsButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(presentSettings), for: .touchUpInside)
        button.setImage(RevoImages.settingsIcon, for: .normal)
        return button
    }()
    
    private let editPreviewStyleButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(editPreviewStyle), for: .touchUpInside)
        button.setImage(RevoImages.editPreviewIcon, for: .normal)
        button.isHidden = true
        return button
    }()
    
    private let switchCamInfoButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(infoButtonPress), for: .touchUpInside)
        button.setImage(RevoImages.infoIcon, for: .normal)
        return button
    }()
    
    private let presentationButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.switchFullScreenPreview, for: .normal)
        button.addTarget(self, action: #selector(changeRecordingPresentation), for: .touchUpInside)
        return button
    }()
    
    let cameraSelectionButton: UIButton = {
        let button = UIButton()
        button.setTitle("1", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.addUIBlurEffectWith(effect: UIBlurEffect(style: .light), cornerRadius: 20)
        button.addTarget(self, action: #selector(cameraSelectionPress), for: .touchUpInside)
        return button
    }()
    
    private let flashButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.flashOffIcon, for:.normal)
        button.addTarget(self, action: #selector(toggleTorchMode), for: .touchUpInside)
        button.addUIBlurEffectWith(effect: UIBlurEffect(style: .light), cornerRadius: 20)
        return button
    }()
    
    private let switchButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.switchPreviews, for:.normal)
        button.addTarget(self, action: #selector(switchPreviews), for: .touchUpInside)
        button.addUIBlurEffectWith(effect: UIBlurEffect(style: .light), cornerRadius: 20)
        return button
    }()
    
    private let exposureButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.isoIcon, for:.normal)
        button.addTarget(self, action: #selector(changeExposure), for: .touchUpInside)
        button.addUIBlurEffectWith(effect: UIBlurEffect(style: .light), cornerRadius: 20)
        return button
    }()
    
    let cameraSettingSlider: UISlider = {
        let slider = UISlider()
        slider.addTarget(self, action: #selector(exposureSliderChanged), for: .valueChanged)
        slider.minimumTrackTintColor = UIColor.white.withAlphaComponent(0.3)
        slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.3)
        slider.isHidden = true
        slider.value = 0
        return slider
    }()
    
    private let zoomButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.zoomIcon, for:.normal)
        button.addTarget(self, action: #selector(changeZoom), for: .touchUpInside)
        button.addUIBlurEffectWith(effect: UIBlurEffect(style: .light), cornerRadius: 20)
        return button
    }()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    //
    //MARK: - View Did Load
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNotificationObservers()
        addGestureRecognisers()
        configureViews()
    }
        
    override func viewDidAppear(_ animated: Bool) {
        updateLibraryButtonThumbnail()
        
        // Hide the presentationButton button to limit the user's options for
        // toggling features which use AVCaptureMultiCamSession.
        if !AVCaptureMultiCamSession.isMultiCamSupported {
            presentationButton.isHidden = true
        }
    }
    
    private func configureNotificationObservers() {
        // Observe when new preview style has been saved
        NotificationCenter.default.addObserver(self, selector: #selector(savePreviewStyle), name: NSNotification.Name(rawValue: "savedStyle"), object: nil)
        
        // Recognising device orientation changes
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    private func addGestureRecognisers() {
        recordingButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(recordButtonTap)))
    }
    
    @objc func orientationChanged(notification: Notification) {
        let deviceOrientation = UIDevice.current.orientation
        var angle: Double?
        
        switch deviceOrientation {
        case .portrait:
            angle = 0
        case .portraitUpsideDown:
            angle = Double.pi
        case .landscapeLeft:
            angle = Double.pi / 2
        case .landscapeRight:
            angle = -Double.pi / 2
        default:
            break
        }
        
        if let angle = angle {
            let transform = CGAffineTransform(rotationAngle: CGFloat(angle))
            // Saved video will be rotated to reflect device orientation
            assetWriter.rotationAngle = -CGFloat(angle)
            
            // Buttons will be rotated to reflect device orientation
            UIView.animate(withDuration: 0.3, animations: {
                self.presentationButton.transform = transform
                self.editPreviewStyleButton.transform = transform
                self.recordingModeButton.transform = transform
                self.exposureButton.transform = transform
                self.settingsButton.transform = transform
                self.libraryButton.transform = transform
                self.switchButton.transform = transform
                self.flashButton.transform = transform
                self.zoomButton.transform = transform
            })
        }
    }
    
    private func updateLibraryButtonThumbnail() {
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
    
    private func configureViews() {
        // Added PassThroughView that allows touches to fall through to lower window. This
        // passThroughView is the lowest sub-view, any UIViews above will respond to touches
        
        let passThroughView = PassThroughView()
        passThroughView.frame = view.frame
        view.addSubview(passThroughView)
        
        // Regular views added above passThroughView
        view.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.centerYAnchor.constraint(equalTo: view.topAnchor, constant: 55).isActive = true
        timeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        timeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        view.addSubview(settingsButton)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor, constant: 0).isActive = true
        settingsButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
        
        view.addSubview(editPreviewStyleButton)
        editPreviewStyleButton.translatesAutoresizingMaskIntoConstraints = false
        editPreviewStyleButton.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor, constant: 0).isActive = true
        editPreviewStyleButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
        
        view.addSubview(switchCamInfoButton)
        switchCamInfoButton.translatesAutoresizingMaskIntoConstraints = false
        switchCamInfoButton.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor, constant: 0).isActive = true
        switchCamInfoButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
        
        view.addSubview(libraryButton)
        libraryButton.translatesAutoresizingMaskIntoConstraints = false
        libraryButton.centerYAnchor.constraint(equalTo: view.bottomAnchor, constant: -80).isActive = true
        libraryButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
        libraryButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        libraryButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        view.addSubview(cameraSelectionButton)
        cameraSelectionButton.translatesAutoresizingMaskIntoConstraints = false
        cameraSelectionButton.centerYAnchor.constraint(equalTo: libraryButton.centerYAnchor).isActive = true
        cameraSelectionButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
        cameraSelectionButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        cameraSelectionButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.addSubview(recordingModeButton)
        recordingModeButton.translatesAutoresizingMaskIntoConstraints = false
        recordingModeButton.centerYAnchor.constraint(equalTo: libraryButton.centerYAnchor).isActive = true
        recordingModeButton.leftAnchor.constraint(equalTo: libraryButton.rightAnchor, constant: 25).isActive = true
        recordingModeButton.widthAnchor.constraint(equalToConstant: 48).isActive = true
        
        view.addSubview(presentationButton)
        presentationButton.translatesAutoresizingMaskIntoConstraints = false
        presentationButton.centerYAnchor.constraint(equalTo: libraryButton.centerYAnchor).isActive = true
        presentationButton.rightAnchor.constraint(equalTo: cameraSelectionButton.leftAnchor, constant: -30).isActive = true
        presentationButton.widthAnchor.constraint(equalToConstant: 48).isActive = true
        
        view.addSubview(recordingButton)
        recordingButton.translatesAutoresizingMaskIntoConstraints = false
        recordingButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        recordingButton.centerYAnchor.constraint(equalTo: libraryButton.centerYAnchor).isActive = true
        recordingButton.heightAnchor.constraint(equalToConstant: 75).isActive = true
        recordingButton.widthAnchor.constraint(equalToConstant: 75).isActive = true
        
        view.addSubview(switchButton)
        switchButton.translatesAutoresizingMaskIntoConstraints = false
        switchButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant:  -30).isActive = true
        switchButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16).isActive = true
        switchButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        switchButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.addSubview(flashButton)
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        flashButton.bottomAnchor.constraint(equalTo: switchButton.topAnchor, constant: -20).isActive = true
        flashButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16).isActive = true
        flashButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        flashButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.addSubview(exposureButton)
        exposureButton.translatesAutoresizingMaskIntoConstraints = false
        exposureButton.topAnchor.constraint(equalTo: switchButton.bottomAnchor, constant: 20).isActive = true
        exposureButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16).isActive = true
        exposureButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        exposureButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.addSubview(zoomButton)
        zoomButton.translatesAutoresizingMaskIntoConstraints = false
        zoomButton.topAnchor.constraint(equalTo: exposureButton.bottomAnchor, constant: 20).isActive = true
        zoomButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16).isActive = true
        zoomButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        zoomButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.addSubview(cameraSettingSlider)
        cameraSettingSlider.translatesAutoresizingMaskIntoConstraints = false
        
        // Slider is rotated to become a vertical slider
        cameraSettingSlider.transform = CGAffineTransform(rotationAngle: CGFloat.pi * -90 / 180)
        let rotatedHeight: CGFloat = 250
        
        cameraSettingSlider.topAnchor.constraint(equalTo: switchButton.bottomAnchor, constant: 20).isActive = true
        cameraSettingSlider.rightAnchor.constraint(equalTo: view.rightAnchor, constant: (rotatedHeight / 2) - 30).isActive = true
        // Rotated the width will act as the sliders height and height as width
        cameraSettingSlider.widthAnchor.constraint(equalToConstant: rotatedHeight).isActive = true
        cameraSettingSlider.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
    //MARK: - Record Screen
    
    @objc private func recordButtonTap(tapGesture: UITapGestureRecognizer) {
        
        switch recordingMode {
        case .video:
            if screenRecorder.isRecording {
                recordingButton.animateRecordingButton()
                alertMultiViewOfRecordingEnd()
                animateControlsAlphaTo(1.0)
                stopRecordingTime()
                stopRecording()
            } else {
                startRecord()
            }
        case .live:
            if broadcastVC.isBroadcasting {
                stopBroadcast()
            } else {
                startBroadcast()
            }
        }
    }
    
    private func startRecord() {
        do {
            try assetWriter.setUpWriter()
        } catch {
            Alert.showBasicAlert(title: "Recording Error".localized, message: error.localizedDescription, vc: self)
            return
        }
        screenRecorder.isMicrophoneEnabled = true
        screenRecorder.startCapture(handler: { cmSampleBuffer, rpSampleBufferType, error in
            
            if let error = error {
                DispatchQueue.main.sync {
                    Alert.showBasicAlert(title: "Recording Error".localized, message: error.localizedDescription, vc: self)
                    self.stopRecording()
                }
            } else {
                self.assetWriter.writeBuffer(cmSampleBuffer, rpSampleType: rpSampleBufferType) { error in
                    guard let error = error else { return }
                    DispatchQueue.main.async {
                        Alert.showBasicAlert(title: "Recording Error".localized, message: error.localizedDescription, vc: self)
                        self.stopRecording()
                    }
                }
            }
        }) { error in
            if let error = error  {
                DispatchQueue.main.async {
                    Alert.showBasicAlert(title: "Recording Error".localized, message: error.localizedDescription, vc: self)
                    self.stopRecording()
                }
            } else {
                self.recordingButton.animateRecordingButton()
                self.alertMultiViewOfRecordingStart()
                self.animateControlsAlphaTo(0.0)
                self.startRecordingTime()
            }
        }
    }
    
    private func stopRecording() {
        // Log the event to Firebase Analytics
        RevoAnalytics.logRecordingEvent(in: recordingMode, using: presentationMode)
        recordingButton.isUserInteractionEnabled = false
        libraryButton.isUserInteractionEnabled = false
        recordingButton.showActivitySpinner()
                
        screenRecorder.stopCapture { error in
            
            if let error = error {
                print(error.localizedDescription)
                Alert.showBasicAlert(title: "Recording Error".localized, message: error.localizedDescription, vc: self)
            } else {
                self.assetWriter.finishWriting(completionHandler: { url, error in
                    
                    DispatchQueue.main.async {
                        
                        if let error = error {
                            Alert.showBasicAlert(title: "Recording Error".localized, message: error.localizedDescription, vc: self)
                        } else if url != nil {
                            // Recording finished
                            self.recordingButton.isUserInteractionEnabled = true
                            self.libraryButton.isUserInteractionEnabled = true
                            self.recordingButton.hideActivitySpinner()
                            self.updateLibraryButtonThumbnail()
                        }
                    }
                })
            }
        }
    }
    
    
    private func startBroadcast() {
        RPBroadcastActivityViewController.load { broadcastAVC, error in
            
            guard error == nil else {
                print("Cannot load Broadcast Activity View Controller.")
                return
            }
            
            if let broadcastAVC = broadcastAVC {
                broadcastAVC.delegate = self
                self.present(broadcastAVC, animated: true, completion: nil)
            }
        }
    }
    
    private func stopBroadcast() {
        broadcastVC.finishBroadcast { error in
            if error == nil {
                // Broadcast finished
                DispatchQueue.main.async {
                    self.recordingButton.animateRecordingButton()
                    self.alertMultiViewOfRecordingEnd()
                    self.animateControlsAlphaTo(1.0)
                    self.stopRecordingTime()
                }
            }
        }
    }
    
    private func animateControlsAlphaTo(_ newAlpha: CGFloat) {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            self.editPreviewStyleButton.alpha = newAlpha
            self.cameraSelectionButton.alpha = newAlpha
            self.presentationButton.alpha = newAlpha
            self.recordingModeButton.alpha = newAlpha
            self.libraryButton.alpha = newAlpha
        }, completion: nil)
    }
    
    let webView = WebVC()
    
    @objc private func changeRecordingPresentation() {
        switch presentationMode {
        case .switchCam:
            presentationButton.setImage(RevoImages.multiScreenIcon, for: .normal)
            delegate?.changePresentationTo(mode: .pip)
            // The switchCamInfoButton is only shown in switchCam mode. The style can not be
            // edited in switchCam mode so editPreviewStyleButton is hidden.
            editPreviewStyleButton.isHidden = false
            switchCamInfoButton.isHidden = true
            presentationMode = .pip
        case .pip:
            presentationButton.setImage(RevoImages.splitScreenIcon, for: .normal)
            delegate?.changePresentationTo(mode: .splitScreen)
            presentationMode = .splitScreen
        case .splitScreen:
            presentationButton.setImage(RevoImages.webIcon, for: .normal)
            delegate?.changePresentationTo(mode: .web)
            webView.modalPresentationStyle = .fullScreen
            present(webView, animated: true, completion: nil)
            presentationMode = .web
        case .web:
            presentationButton.setImage(RevoImages.switchFullScreenPreview, for: .normal)
            delegate?.changePresentationTo(mode: .switchCam)
            editPreviewStyleButton.isHidden = true
            switchCamInfoButton.isHidden = false
            presentationMode = .switchCam
        }
    }
    
    @objc private func recordingModePress() {
        switch recordingMode {
        case .live:
            recordingModeButton.setImage(RevoImages.cameraIcon(), for: .normal)
            recordingButton.recordingMode = .video
            recordingMode = .video
        case .video:
            checkIfUserIsAwareOfLiveMode()
            recordingModeButton.setImage(RevoImages.liveButtonIcon, for: .normal)
            recordingButton.recordingMode = .live
            recordingMode = .live
        }
    }
    
    private func checkIfUserIsAwareOfLiveMode() {
        let userIsAware = UserDefaults.standard.bool(forKey: "userIsAwareOfLiveMode")
        // Make sure that the user has not seen this message before
        if !userIsAware {
            Alert.showBasicAlert(title: "Live Broadcasting".localized, message: "live_broadcasting_message".localized, vc: self)
            UserDefaults.standard.setValue(true, forKey: "userIsAwareOfLiveMode")
        }
    }
    
    private func startRecordingTime() {
        var runCount: Double = 0
        
        recordingTime = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            runCount += 1
            self.timeLabel.text = Time.asString(from: runCount)
        }
    }
    
    private func stopRecordingTime() {
        recordingTime.invalidate()
        timeLabel.text = Time.asString(from: 0.0)
    }
    
    @objc private func toggleTorchMode() {
        switch torchMode {
        case .off:
            torchMode = .on
            flashButton.setImage(RevoImages.flashOnIcon, for: .normal)
            delegate?.changeTorchTo(mode: torchMode)
        case .on:
            torchMode = .off
            flashButton.setImage(RevoImages.flashOffIcon, for: .normal)
            delegate?.changeTorchTo(mode: torchMode)
        }
    }
    
    @objc private func editPreviewStyle() {
        switch editingMode {
        case .ready:
            editPreviewStyleButton.setImage(RevoImages.cancelEditPreviewIcon, for: .normal)
            editingMode = .editing
        case .editing:
            editingMode = .ready
            editPreviewStyleButton.setImage(RevoImages.editPreviewIcon, for: .normal)
        }
        delegate?.editPreviewStyleFor(mode: presentationMode)
        view.bringSubviewToFront(editPreviewStyleButton)
    }
    
    private let regularSwitchCamTitle = "Switch Mode".localized
    private let unSupportedTitle = "Device Unsupported".localized
    private let regularSwitchCamMessage = "switchMode_message".localized
    private let unSupportedMessage = "device_unsupported_message".localized
    
    @objc private func infoButtonPress() {
        var title: String
        var message: String
        
        if AVCaptureMultiCamSession.isMultiCamSupported {
            title = regularSwitchCamTitle
            message = regularSwitchCamMessage
        } else {
            title = unSupportedTitle
            message = unSupportedMessage
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Got it".localized, style: .default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @objc private func savePreviewStyle() {
        editPreviewStyleButton.setImage(RevoImages.editPreviewIcon, for: .normal)
        editingMode = .ready
    }
    
    
    @objc private func cameraSelectionPress(sender: UIButton) {
        // This will check which current camera is selected then toggle to
        // the next available from the devicesAvailable array
        
        let zoomFactorString = sender.titleLabel!.text!
        let currentIndex = devicesAvailable.firstIndex(of: zoomFactorString)!
        var newIndex = currentIndex + 1
        
        if newIndex != devicesAvailable.count {
            cameraSelectionButton.setTitle(devicesAvailable[newIndex], for: .normal)
        } else {
            // Current camera is last in the array so toggle back to beginning
            cameraSelectionButton.setTitle(devicesAvailable[0], for: .normal)
            newIndex = 0
        }
        
        let newZoomFactor = devicesAvailable[newIndex]
        
        switch newZoomFactor {
        case "0.5":
            delegate?.cameraSelectionOf(selection: .ultraWide)
        case "1":
            delegate?.cameraSelectionOf(selection: .wide)
        case "1.5":
            delegate?.cameraSelectionOf(selection: .telephoto)
        default:
            break
        }
    }
    
    @objc func visitLibraryVC() {
        if torchMode == .on {
            toggleTorchMode()
        }
        
        let libraryVC = LibraryVC()
        libraryVC.modalPresentationStyle = .fullScreen
        self.present(libraryVC, animated: true, completion: nil)
    }
    
    @objc private func switchPreviews() {
        delegate?.switchPreviewsFor(mode: presentationMode)
        cameraSettingSlider.isHidden = true
    }
    
    @objc private func changeExposure() {
        guard let exposureTargetBiasMinMax = currentCameraExposureTargetBiasMinMax?(),
              let exposureTargetBias = currentCameraExposureTargetBias?() else {
            return
        }
        cameraSettingSlider.minimumValue = exposureTargetBiasMinMax[0]
        cameraSettingSlider.maximumValue = exposureTargetBiasMinMax[1]
        cameraSettingSlider.value = exposureTargetBias
        hideOrShowSliderFor(setting: .exposure)
    }
    
    @objc private func changeZoom() {
        guard let maxZoomFactor = currentCameraMaxZoomFactor?(),
              let zoomFactor = currentCameraZoomFactor?() else {
            return
        }
        // maximumValue is divided by 4 to limit zoom
        cameraSettingSlider.maximumValue = Float(maxZoomFactor) / 4
        cameraSettingSlider.minimumValue = 1
        cameraSettingSlider.value = Float(zoomFactor)
        hideOrShowSliderFor(setting: .zoom)
    }
    
    @objc private func exposureSliderChanged(slider: UISlider, event: UIEvent) {
        guard let setting = currentSetting else { return }
        delegate?.updateCapture(setting: setting, with: slider)
        
        if let touchEvent = event.allTouches?.first {
            if touchEvent.phase == .ended {
                startSliderRemovalTimer()
            } else if touchEvent.phase == .began {
                sliderRemovalTimer.invalidate()
            }
        }
    }
    
    /// Toggles the slider's isHidden property depending on the state of the property
    /// and which current setting is being edited.
    private func hideOrShowSliderFor(setting: CameraSetting) {
        sliderRemovalTimer.invalidate()
        startSliderRemovalTimer()
        
        if cameraSettingSlider.isHidden {
            cameraSettingSlider.isHidden = false
        } else if currentSetting == setting {
            cameraSettingSlider.isHidden = true
            sliderRemovalTimer.invalidate()
        }
        currentSetting = setting
    }
    
    /// Will remove slider if dormant for greater than 3 seconds
    private func startSliderRemovalTimer() {
        sliderRemovalTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            self.cameraSettingSlider.isHidden = true
        }
    }
    
    @objc private func presentSettings() {
        self.present(settingsVC, animated: true, completion: nil)
    }
    
    
}

extension RecordingControlsVC: RPBroadcastActivityViewControllerDelegate {
    
    func broadcastActivityViewController(_ broadcastActivityViewController: RPBroadcastActivityViewController, didFinishWith broadcastController: RPBroadcastController?, error: Error?) {
        guard error == nil else {
            print("Broadcast Activity Controller is not available.")
            broadcastActivityViewController.dismiss(animated: true)
            return
        }
        
        guard let broadcastController = broadcastController else {
            // Cancel
            return
        }
        
        broadcastController.delegate = self
        
        broadcastActivityViewController.dismiss(animated: true) {
            
            self.recordingButton.showActivitySpinner()
            
            broadcastController.startBroadcast { error in
                
                if error == nil {
                    print("Broadcast started successfully!")
                    self.recordingButton.animateRecordingButton()
                    self.recordingButton.hideActivitySpinner()
                    self.alertMultiViewOfRecordingStart()
                    self.animateControlsAlphaTo(0.0)
                    self.startRecordingTime()
                } else {
                    print("Error")
                }
            }
        }
    }
    
    
}

extension RecordingControlsVC: RPBroadcastControllerDelegate {
    
    func broadcastController(_ broadcastController: RPBroadcastController, didUpdateServiceInfo serviceInfo: [String : NSCoding & NSObjectProtocol]) {
        // TODO: Show the connection is successful or not to the user
        print(serviceInfo)
    }
    
}
