//
//  HiddenHUDVC.swift
//  Revo
//
//  Created by Waylan Sands on 16/12/20.
//

import UIKit
import ReplayKit
import FirebaseAnalytics
import MobileCoreServices

protocol RecordingDelegate: class {
    func updateCapture(setting: CameraSetting, with slider: UISlider)
    func changeCameraTo(selection: CameraSelection)
    func changeTorchTo(mode: TorchMode)
}

// For handling presentation changes
protocol PresentationDelegate: class {
    func changePresentationTo(mode: PresentationMode)
    func editPreviewStyleFor(mode: PresentationMode)
    func switchPreviewsFor(mode: PresentationMode)
}

// For handling Web Mode actions
protocol WebDelegate: class {
    func goBackwardsWebPage()
    func goForwardWebPage()
}

// For handling Upload Mode actions
protocol UploadDelegate: class {
    func configurePlayerWith(url: URL)
    func toggleVideoGravity()
    func playOrPause()
    func resizeVideo()
    func muteVideo()
}

enum PresentationMode {
    case splitScreen
    case switchCam
    case upload
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

enum PlayerState {
    case playing
    case paused
    case ready
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
    private var playerState: PlayerState = .ready
    
    // Delegate properties
    weak var presentationDelegate: PresentationDelegate?
    weak var recordingDelegate: RecordingDelegate?
    weak var uploadDelegate: UploadDelegate?
    weak var webDelegate: WebDelegate?

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
    
    /// Used for selecting camera modes.
    let modeSelectView = ModeSelectView()
    
    /// Custom controls used when in Web Mode.
    private let webControlsView = WebControlsView()

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
    
    // MARK: Record Button
    private let recordingButton = RecordButtonView()
    
    private lazy var gradientLayer: CAGradientLayer = {
        let topColor =  UIColor.black.withAlphaComponent(0.7).cgColor
        let bottomColor =  UIColor.black.withAlphaComponent(0).cgColor
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [bottomColor, topColor]
        gradientLayer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 170)
        return gradientLayer
    }()
        
    private lazy var lowerDarkView: UIView = {
        let view = UIView()
        view.layer.addSublayer(gradientLayer)
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00:00"
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 19, weight: .semibold)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 10
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    private let stackView: UIStackView = {
       let view = UIStackView()
        view.distribution = .equalSpacing
        view.alignment = .center
        return view
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
    
    // MARK: - Upload Mode Views
    
    private let imagePicker = UIImagePickerController()
    
    private lazy var uploadButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(uploadButtonTapped), for: .touchUpInside)
        button.setImage(RevoImages.whiteUploadIcon, for: .normal)
        button.isHidden = true
        return button
    }()
    
    private let uploadLabel: UILabel = {
        let label = UILabel()
        label.text = "Upload Video"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    private let playButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.miniPlayIcon, for:.normal)
        button.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        button.addUIBlurEffectWith(effect: UIBlurEffect(style: .light), cornerRadius: 20)
        return button
    }()
    
    let aspectButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.aspectFillIcon, for:.normal)
        button.addTarget(self, action: #selector(resizeButtonTapped), for: .touchUpInside)
        button.addUIBlurEffectWith(effect: UIBlurEffect(style: .light), cornerRadius: 20)
        return button
    }()
    
    private let muteButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.smallAudioIcon, for:.normal)
        button.addTarget(self, action: #selector(muteButtonTapped), for: .touchUpInside)
        button.addUIBlurEffectWith(effect: UIBlurEffect(style: .light), cornerRadius: 20)
        return button
    }()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    //MARK: - View Did Load
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addGestureRecognisers()
        configureObservers()
        configureDelegates()
        configureViews()
        
    }
        
    override func viewDidAppear(_ animated: Bool) {
        updateLibraryButtonThumbnail()
    }
    
    private func configureDelegates() {
        webControlsView.delegate = self
        modeSelectView.delegate = self
    }
    
    private func configureObservers() {
        // Observe when new preview style has been saved
        NotificationCenter.default.addObserver(self, selector: #selector(savePreviewStyle), name: NSNotification.Name(rawValue: "savedStyle"), object: nil)
        
        // Recognising device orientation changes
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        // Observe when MainRecordingVC's webToolBarView is triggering actions
        NotificationCenter.default.addObserver(self, selector: #selector(animateWebToolBarDown), name: NSNotification.Name(rawValue: "animateWebToolBarDown"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(animateWebToolBarUp), name: NSNotification.Name(rawValue: "animateWebToolBarUp"), object: nil)
        
        // Upload Player Finished
        NotificationCenter.default.addObserver(self, selector: #selector(playerFinished), name: NSNotification.Name(rawValue: "playerFinished"), object: nil)
    }

    
    private func addGestureRecognisers() {
        recordingButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(recordButtonTap)))
    }
    
    @objc func orientationChanged() {
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
                self.editPreviewStyleButton.transform = transform
                self.cameraSelectionButton.transform = transform
                self.recordingModeButton.transform = transform
                self.exposureButton.transform = transform
                self.settingsButton.transform = transform
                self.libraryButton.transform = transform
                self.aspectButton.transform = transform
                self.switchButton.transform = transform
                self.flashButton.transform = transform
                self.zoomButton.transform = transform
                self.playButton.transform = transform
                self.muteButton.transform = transform
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
        timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: timeLabel.intrinsicContentSize.width + 20).isActive = true
        timeLabel.heightAnchor.constraint(equalToConstant: timeLabel.font.lineHeight + 8).isActive = true

        if UIScreen.main.nativeBounds.height > 1334 {
            timeLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 45).isActive = true
        } else {
            // Device is an iPhone SE, 6S, 7 , 8 or smaller
            timeLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 25).isActive = true
        }
        
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
        
        view.addSubview(lowerDarkView)
        lowerDarkView.translatesAutoresizingMaskIntoConstraints = false
        lowerDarkView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        lowerDarkView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        lowerDarkView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        if UIScreen.main.nativeBounds.height > 1334 {
            lowerDarkView.heightAnchor.constraint(equalToConstant: 170).isActive = true
        } else {
            // Device is an iPhone SE, 6S, 7 , 8 or smaller
            lowerDarkView.heightAnchor.constraint(equalToConstant: 140).isActive = true
        }
        
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
        stackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
//        stackView.heightAnchor.constraint(equalToConstant: 70).isActive = true
        if UIScreen.main.nativeBounds.height > 1334 {
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60).isActive = true
        } else {
            // Device is an iPhone SE, 6S, 7 , 8 or smaller
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -35).isActive = true
        }
        
        stackView.addArrangedSubview(libraryButton)
        libraryButton.translatesAutoresizingMaskIntoConstraints = false
        libraryButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        libraryButton.widthAnchor.constraint(equalToConstant: 48).isActive = true
        
        stackView.addArrangedSubview(recordingModeButton)
        recordingModeButton.translatesAutoresizingMaskIntoConstraints = false
        recordingModeButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        recordingModeButton.widthAnchor.constraint(equalToConstant: 48).isActive = true
        
        stackView.addArrangedSubview(recordingButton)
        recordingButton.translatesAutoresizingMaskIntoConstraints = false
        recordingButton.heightAnchor.constraint(equalToConstant: 70).isActive = true
        recordingButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
        
        stackView.addArrangedSubview(cameraSelectionButton)
        cameraSelectionButton.translatesAutoresizingMaskIntoConstraints = false
        cameraSelectionButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        cameraSelectionButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        stackView.addArrangedSubview(switchButton)
        switchButton.translatesAutoresizingMaskIntoConstraints = false
        switchButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        switchButton.widthAnchor.constraint(equalToConstant: 48).isActive = true
        
        view.addSubview(flashButton)
        flashButton.frame = CGRect(x: 16, y:  view.center.y - 50, width: 40, height: 40)
        
        view.addSubview(exposureButton)
        exposureButton.frame = CGRect(x: 16, y: flashButton.frame.minY + 60, width: 40, height: 40)
        
        view.addSubview(zoomButton)
        zoomButton.frame = CGRect(x: 16, y: exposureButton.frame.minY + 60, width: 40, height: 40)
        
        view.addSubview(modeSelectView)
        modeSelectView.translatesAutoresizingMaskIntoConstraints = false
        modeSelectView.bottomAnchor.constraint(equalTo: recordingButton.topAnchor, constant: 5).isActive = true
        modeSelectView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        modeSelectView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        modeSelectView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        view.addSubview(webControlsView)
        webControlsView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height, width: UIScreen.main.bounds.width, height: 120)
        
        view.addSubview(cameraSettingSlider)
        cameraSettingSlider.translatesAutoresizingMaskIntoConstraints = false
        
        // Slider is rotated to become a vertical slider
        cameraSettingSlider.transform = CGAffineTransform(rotationAngle: CGFloat.pi * -90 / 180)
        let rotatedHeight: CGFloat = 250
        
        cameraSettingSlider.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        cameraSettingSlider.rightAnchor.constraint(equalTo: view.rightAnchor, constant: (rotatedHeight / 2) - 30).isActive = true
        // Rotated the width will act as the sliders height and height as width
        cameraSettingSlider.widthAnchor.constraint(equalToConstant: rotatedHeight).isActive = true
        cameraSettingSlider.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        // For Upload Mode
        
        view.addSubview(uploadButton)
        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        uploadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        uploadButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20).isActive = true
        
        view.addSubview(uploadLabel)
        uploadLabel.translatesAutoresizingMaskIntoConstraints = false
        uploadLabel.topAnchor.constraint(equalTo: uploadButton.bottomAnchor, constant: 15).isActive = true
        uploadLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        uploadLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        view.addSubview(playButton)
        playButton.frame = CGRect(x: -50, y:  view.center.y - 50, width: 40, height: 40)
        
        view.addSubview(aspectButton)
        aspectButton.frame = CGRect(x: -50, y: playButton.frame.minY + 60, width: 40, height: 40)
        
        view.addSubview(muteButton)
        muteButton.frame = CGRect(x: -50, y: aspectButton.frame.minY + 60, width: 40, height: 40)
    }
    
    //MARK: - Record Screen
    
    @objc private func recordButtonTap() {
        switch recordingMode {
        case .video:
            if screenRecorder.isRecording {
                alertMultiViewOfRecordingEnd()
                animateControlsAlphaTo(1.0)
                animateRecordingButton()
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
    
    private func configureAudioSession(start: Bool) {
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            if presentationMode == .upload && start {
                // We set the audioSession to be aware that we are both recording and playing a video.
                try audioSession.setCategory(.playAndRecord, mode: .default, policy: .default, options: .defaultToSpeaker)
            } else {
                // We set the audioSession to the default.
                try audioSession.setCategory(.soloAmbient, mode: .default, options: [])
            }
        } catch {
            print("Failed to set audio session category.")
        }
    }
    
    
    private func startRecord() {
        do {
            try assetWriter.setUpWriter()
        } catch {
            Alert.showBasicAlert(title: "Recording Error".localized, message: error.localizedDescription, vc: self)
            return
        }
       
        // Disable app from going to sleep without interactions
        UIApplication.shared.isIdleTimerDisabled = true
        screenRecorder.isMicrophoneEnabled = true
        configureAudioSession(start: true)
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
                DispatchQueue.main.async {
                    self.alertMultiViewOfRecordingStart()
                    self.animateControlsAlphaTo(0.0)
                    self.animateRecordingButton()
                    self.startRecordingTime()
                }
            }
        }
    }
    
    // Determine which recording button has been pressed
    private func animateRecordingButton() {
        switch presentationMode {
        case .web:
            webControlsView.recordingButton.animateRecordingButton()
        default:
            recordingButton.animateRecordingButton()
        }
    }
    
    private func stopRecording() {
        // Log the event to Firebase Analytics
        RevoAnalytics.logRecordingEvent(in: recordingMode, using: presentationMode)
        enableControlsWhileVideoProcesses(enable: false)
        configureAudioSession(start: false)
        stopPlaybackIfInUploadMode()
        
        // Re-enable app to go to sleep without interactions
        UIApplication.shared.isIdleTimerDisabled = false

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
                            self.enableControlsWhileVideoProcesses(enable: true)
                        }
                    }
                })
            }
        }
    }
    
    private func stopPlaybackIfInUploadMode() {
        if presentationMode == .upload && playerState == .playing {
            playButton.setImage(RevoImages.miniPlayIcon, for: .normal)
            uploadDelegate?.playOrPause()
            playerState = .paused
        }
    }

    
    // Do not allow users to navigate to the Library or start another
    // recording until the previous video has been written.
    private func enableControlsWhileVideoProcesses(enable: Bool) {
        switch presentationMode {
        case .web:
            webControlsView.recordingButton.isUserInteractionEnabled = enable
            webControlsView.libraryButton.isUserInteractionEnabled = enable
            if enable {
                webControlsView.recordingButton.hideActivitySpinner()
                webControlsView.updateLibraryButtonThumbnail()
            } else {
                webControlsView.recordingButton.showActivitySpinner()
            }
        default:
            recordingButton.isUserInteractionEnabled = enable
            libraryButton.isUserInteractionEnabled = enable
            if enable {
                recordingButton.hideActivitySpinner()
                updateLibraryButtonThumbnail()
            } else {
                recordingButton.showActivitySpinner()
            }
        }
    }
    
    
    private func startBroadcast() {
        // Disable app from going to sleep without interactions
        UIApplication.shared.isIdleTimerDisabled = true
        
        configureAudioSession(start: true)
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
        // Re-enable app to go to sleep without interactions
        UIApplication.shared.isIdleTimerDisabled = false
        
        configureAudioSession(start: false)
        broadcastVC.finishBroadcast { error in
            if error == nil {
                // Broadcast finished
                DispatchQueue.main.async {
                    self.alertMultiViewOfRecordingEnd()
                    self.animateControlsAlphaTo(1.0)
                    self.animateRecordingButton()
                    self.stopRecordingTime()
                }
            }
        }
    }
    
    private func animateControlsAlphaTo(_ newAlpha: CGFloat) {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            self.editPreviewStyleButton.alpha = newAlpha
            self.cameraSelectionButton.alpha = newAlpha
            self.recordingModeButton.alpha = newAlpha
            self.switchCamInfoButton.alpha = newAlpha
            self.settingsButton.alpha = newAlpha
            self.modeSelectView.alpha = newAlpha
            self.libraryButton.alpha = newAlpha
            self.lowerDarkView.alpha = newAlpha
            self.switchButton.alpha = newAlpha
        }, completion: nil)
    }
    
    // MARK: - Update Presentation Mode
    private func updatePresentation(to mode: PresentationMode) {
        switch mode {
        case .switchCam:
            presentationDelegate?.changePresentationTo(mode: .switchCam)
            animateUploadSettingButtonsTo(newX: -50)
            editPreviewStyleButton.isHidden = true
            switchCamInfoButton.isHidden = false
            enableSwitchAndCameraButtons()
            presentationMode = .switchCam
            animateInSettingButtons()
            hideUploadButton()
        case .pip:
            presentationDelegate?.changePresentationTo(mode:.pip)
            // The switchCamInfoButton is only shown in switchCam mode. The style can not be
            // edited in switchCam mode so editPreviewStyleButton is hidden.
            animateUploadSettingButtonsTo(newX: -50)
            editPreviewStyleButton.isHidden = false
            switchCamInfoButton.isHidden = true
            enableSwitchAndCameraButtons()
            animateInSettingButtons()
            presentationMode = .pip
            hideUploadButton()
        case .splitScreen:
            presentationDelegate?.changePresentationTo(mode: .splitScreen)
            animateUploadSettingButtonsTo(newX: -50)
            editPreviewStyleButton.isHidden = false
            switchCamInfoButton.isHidden = true
            presentationMode = .splitScreen
            enableSwitchAndCameraButtons()
            animateInSettingButtons()
            hideUploadButton()
        case .web:
            webControlsView.updateLibraryButtonThumbnail()
            presentationDelegate?.changePresentationTo(mode: .web)
            animateUploadSettingButtonsTo(newX: -50)
            enableSwitchAndCameraButtons()
            presentationMode = .web
            hideUploadButton()
            hideControls()
        case .upload:
            presentationDelegate?.changePresentationTo(mode: .upload)
            switchCamInfoButton.isHidden = true
            disableSwitchAndCameraButtons()
            presentationMode = .upload
            animateOutSettingButtons()
            configureForUploadMode()
            playerState = .ready
            unhideUploadButton()
        }
    }
    
    private func disableSwitchAndCameraButtons() {
        cameraSelectionButton.isUserInteractionEnabled = false
        switchButton.isUserInteractionEnabled = false
        editPreviewStyleButton.isHidden = false
        switchButton.alpha = 0.4
        
        // Check that devicesAvailable is greater than one rear device otherwise
        // there is no extra devices for cameraSelectionButton to toggle to.
        if devicesAvailable.count > 1 {
            cameraSelectionButton.alpha = 0.4
        }
    }
    
    private func enableSwitchAndCameraButtons() {
        switchButton.isUserInteractionEnabled = true
        switchButton.alpha = 1
        
        // Check that devicesAvailable is greater than one rear device otherwise
        // there is no extra devices for cameraSelectionButton to toggle to.
        if devicesAvailable.count > 1 {
            cameraSelectionButton.isUserInteractionEnabled = true
            cameraSelectionButton.alpha = 1
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
            recordingDelegate?.changeTorchTo(mode: torchMode)
        case .on:
            torchMode = .off
            flashButton.setImage(RevoImages.flashOffIcon, for: .normal)
            recordingDelegate?.changeTorchTo(mode: torchMode)
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
        presentationDelegate?.editPreviewStyleFor(mode: presentationMode)
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
            recordingDelegate?.changeCameraTo(selection: .ultraWide)
        case "1":
            recordingDelegate?.changeCameraTo(selection: .wide)
        case "1.5":
            recordingDelegate?.changeCameraTo(selection: .telephoto)
        default:
            break
        }
    }
    
    @objc func visitLibraryVC() {
        if torchMode == .on {
            toggleTorchMode()
        }
        
        if presentationMode == .upload && playerState == .playing {
            playButton.setImage(RevoImages.miniPlayIcon, for: .normal)
            uploadDelegate?.playOrPause()
            playerState = .paused
        }
        
        let libraryVC = LibraryVC()
        libraryVC.modalPresentationStyle = .fullScreen
        self.present(libraryVC, animated: true, completion: nil)
    }
    
    @objc private func switchPreviews() {
        presentationDelegate?.switchPreviewsFor(mode: presentationMode)
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
        recordingDelegate?.updateCapture(setting: setting, with: slider)
        
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
    
    //MARK: - Upload Mode
    
    private func configureForUploadMode() {
        aspectButton.setImage(RevoImages.aspectFillIcon, for: .normal)
        muteButton.setImage(RevoImages.smallAudioIcon, for: .normal)
        playButton.setImage(RevoImages.miniPlayIcon, for: .normal)
        playerIsMuted = false
        isAspectFill = true
    }
    
    @objc private func uploadButtonTapped() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary)  else {
            // Show alert
            return
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "hideControls"), object: nil)
                
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            return
        }
        
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        imagePicker.sourceType = .photoLibrary
        imagePicker.modalPresentationStyle = .fullScreen
        imagePicker.videoExportPreset = AVAssetExportPresetPassthrough
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
                
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc func playerFinished() {
        playButton.setImage(RevoImages.miniPlayIcon, for: .normal)
        playerState = .ready
    }
    
    @objc func playButtonTapped() {
        
        switch playerState {
        case .playing:
            uploadDelegate?.playOrPause()
            playButton.setImage(RevoImages.miniPlayIcon, for: .normal)
            playerState = .paused
        case .paused:
            playButton.setImage(RevoImages.miniPauseIcon, for: .normal)
            uploadDelegate?.playOrPause()
            playerState = .playing
            break
        case .ready:
            playButton.setImage(RevoImages.miniPauseIcon, for: .normal)
            uploadDelegate?.playOrPause()
            playerState = .playing
            break
        }
    }
    
    private var isAspectFill = true
    
    @objc func resizeButtonTapped() {
        uploadDelegate?.toggleVideoGravity()
        
        if isAspectFill {
            aspectButton.setImage(RevoImages.aspectFitIcon, for: .normal)
            isAspectFill = false
        } else {
            aspectButton.setImage(RevoImages.aspectFillIcon, for: .normal)
            isAspectFill = true

        }
    }
    
    private var playerIsMuted = false
    
    @objc func muteButtonTapped() {
        uploadDelegate?.muteVideo()
        if playerIsMuted {
            muteButton.setImage(RevoImages.smallAudioIcon, for: .normal)
            playerIsMuted = false
        } else {
            muteButton.setImage(RevoImages.smallAudioOffIcon, for: .normal)
            playerIsMuted = true
        }
    }
    
    private func unhide() {
        uploadLabel.isHidden = false
        uploadButton.isHidden = false
    }
    
    private func hide() {
        uploadLabel.isHidden = true
        uploadButton.isHidden = true
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
                    self.webControlsView.recordingButton.animateRecordingButton()
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
    
    // Web Mode uses it's own controls to handle recording and navigation so we
    // hide the default controls so they do not interfere. Also camera settings
    // buttons are not applicable when in Web Mode so they're hidden too.
    @objc func hideControls() {
        for each in view.subviews {
            if !each.isKind(of: PassThroughView.self) && !each.isKind(of: WebControlsView.self) && each != timeLabel {
                each.isHidden = true
            }
        }
        
        if presentationMode == .upload {
            timeLabel.isHidden = true
        }
        
        if presentationMode == .web {
            timeLabel.isHidden = false
        }
        
    }
    
    // Show the controls when returning from Web Mode (WebVC). This method is called
    // from MainRecordingVC as that is the controller which presents WebVC.
    @objc func showControls() {
        // cameraSettingSlider should be hidden by default.
        for each in view.subviews where each != cameraSettingSlider {
            each.isHidden = false
        }
        
        if devicesAvailable.count == 1 {
            // There is only 1 rear camera available so user is unable to toggle
            // through cameras via the cameraSelectionButton
            cameraSelectionButton.alpha = 0
        }
        
        if presentationMode == .upload {
            switchCamInfoButton.isHidden = true
        }
    }
    
    private func unhideUploadButton() {
        uploadLabel.isHidden = false
        uploadButton.isHidden = false
    }
    
    private func hideUploadButton() {
        uploadLabel.isHidden = true
        uploadButton.isHidden = true
    }
    
    private func animateOutSettingButtons() {
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
            self.flashButton.frame = CGRect(x: -50, y:  self.view.center.y - 50, width: 40, height: 40)
        }, completion: nil)
        UIView.animate(withDuration: 0.1, delay: 0.2, options: .curveEaseIn, animations: {
            self.exposureButton.frame = CGRect(x: -50, y: self.flashButton.frame.minY + 60, width: 40, height: 40)
        }, completion: nil)
        UIView.animate(withDuration: 0.1, delay: 0.4, options: .curveEaseIn, animations: {
            self.zoomButton.frame = CGRect(x: -50, y: self.exposureButton.frame.minY + 60, width: 40, height: 40)
        }, completion: nil)
    }
    
    private func animateInSettingButtons() {
        if self.flashButton.frame.minX == 16 {
            return
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
            self.flashButton.frame = CGRect(x: 16, y: self.view.center.y - 50, width: 40, height: 40)
        }, completion: nil)
        UIView.animate(withDuration: 0.2, delay: 0.2, options: .curveEaseIn, animations: {
            self.exposureButton.frame = CGRect(x: 16, y: self.flashButton.frame.minY + 60, width: 40, height: 40)
        }, completion: nil)
        UIView.animate(withDuration: 0.2, delay: 0.4, options: .curveEaseIn, animations: {
            self.zoomButton.frame = CGRect(x: 16, y: self.exposureButton.frame.minY + 60, width: 40, height: 40)
        }, completion: nil)
    }
    
    private func animateUploadSettingButtonsTo(newX: CGFloat) {
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
            self.playButton.frame = CGRect(x: newX, y:  self.view.center.y - 50, width: 40, height: 40)
        }, completion: nil)
        UIView.animate(withDuration: 0.1, delay: 0.2, options: .curveEaseIn, animations: {
            self.aspectButton.frame = CGRect(x: newX, y: self.playButton.frame.minY + 60, width: 40, height: 40)
        }, completion: nil)
        UIView.animate(withDuration: 0.1, delay: 0.4, options: .curveEaseIn, animations: {
            self.muteButton.frame = CGRect(x: newX, y: self.aspectButton.frame.minY + 60, width: 40, height: 40)
        }, completion: nil)
    }

        
}

extension RecordingControlsVC: RPBroadcastControllerDelegate {
    
    func broadcastController(_ broadcastController: RPBroadcastController, didUpdateServiceInfo serviceInfo: [String : NSCoding & NSObjectProtocol]) {
        // TODO: Show the connection is successful or not to the user
        print(serviceInfo)
    }
    
}

extension RecordingControlsVC: WebToolBarDelegate {
    
    func toggleRecodingMode() {
        recordingModePress()
    }
   
    func goBackwardsAPage() {
        webDelegate?.goBackwardsWebPage()
    }
    
    func goForwardAPage() {
        webDelegate?.goForwardWebPage()
    }
    
    func visitLibrary() {
        visitLibraryVC()
    }
    
    func webRecordingButtonPress() {
        recordButtonTap()
    }
    
    // The two methods below are called by WebVC which manages hiding and
    // showing the WebToolBarView via NotificationCenter.
    
    @objc func animateWebToolBarUp() {
        // Keeps the webControlsView's recoding mode in sync with self when first presenting the webControlsView.
        webControlsView.updateForCamera(mode: self.recordingMode)
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            if UIScreen.main.nativeBounds.height > 1334 {
                self.webControlsView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 120, width: UIScreen.main.bounds.width, height: 120)
            } else {
                self.webControlsView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 90, width: UIScreen.main.bounds.width, height: 90)
            }
        }, completion: nil)
    }
    
    @objc func animateWebToolBarDown() {
        // User has selected to hide the webControlsView
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            if UIScreen.main.nativeBounds.height > 1334 {
                self.webControlsView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height, width: UIScreen.main.bounds.width, height: 120)
            } else {
                self.webControlsView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height, width: UIScreen.main.bounds.width, height: 90)
            }
        }, completion: nil)
    }
    
}

extension RecordingControlsVC: ModeSelectionDelegate {
    
    func changeModeTo(_ mode: PresentationMode) {
        updatePresentation(to: mode)
    }
 
}

extension RecordingControlsVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showControls"), object: nil)
        
        guard  let url = info[.mediaURL] as? URL else {
            print("Fail")
            // Alert message
            return
        }
        uploadDelegate?.configurePlayerWith(url: url)
        hideUploadButton()
        picker.dismiss(animated: true, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.animateUploadSettingButtonsTo(newX: 20)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showControls"), object: nil)
        picker.dismiss(animated: true, completion: nil)
    }
    
    
}


