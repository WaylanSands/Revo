//
//  HiddenHUDVC.swift
//  Revo
//
//  Created by Waylan Sands on 16/12/20.
//

import UIKit
import ReplayKit

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
    case areMissing
    case single
    case dual
    case triple
}

enum EditingState {
    case ready
    case editing
}

class RecordingControlsVC: UIViewController {
    
    // For recording lower UIWindow
    let screenRecorder = RPScreenRecorder.shared()
    let broadcastVC = RPBroadcastController()
    
    // Used to write the audio and video buffers
    let assetWriter = RevoAssetWriter()
    
    var presentationMode: PresentationMode = .switchCam
    var torchMode: TorchMode = .off

    var cameraSelection: CameraSelection = .wide
    var editingMode: EditingState = .ready
    
    var recordingMode: RecordingMode = .video {
        didSet {
            switch recordingMode {
            case .video:
                recordingButton.recordingMode = .video
            case .live:
                recordingButton.recordingMode = .live
            }
        }
    }
    
    let settingsVC = SettingsVC()

    var currentSetting: CameraSetting?
    var devicesAvailable = ["1"]

    /// Removes setting slider if left dormant
    var sliderRemovalTimer = Timer()
    var recordingTime: Timer!

    /// The current rear camera ExposureTargetBiasMinMax as an array [min,max]
    var currentCameraExposureTargetBiasMinMax: (() -> ([Float]))?
    var currentCameraExposureTargetBias: (() -> (Float))?
    var currentCameraMaxZoomFactor: (() -> (CGFloat))?
    var currentCameraZoomFactor: (() -> (CGFloat))?
    var alertMultiViewOfRecordingStart: (() -> Void)!
    var alertMultiViewOfRecordingEnd: (() -> Void)!

    weak var delegate: ControlsDelegate?

    
    // MARK: Record Button
    let recordingButton = RecordButtonView()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00:00"
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 19, weight: .semibold)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()

    let libraryButton: UIButton = {
       let button = UIButton()
        button.setImage(RevoImages.libraryIcon, for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(visitLibraryVC), for: .touchUpInside)
        button.layer.borderWidth = 3
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        return button
    }()

    let recordingModeButton: UIButton = {
       let button = UIButton()
        button.tintColor = .white
        button.addTarget(self, action: #selector(recordingModePress), for: .touchUpInside)
        button.setImage(RevoImages.cameraIcon(), for: .normal)
        return button
    }()

    let settingsButton: UIButton = {
       let button = UIButton()
        button.addTarget(self, action: #selector(presentSettings), for: .touchUpInside)
        button.setImage(RevoImages.settingsIcon, for: .normal)
        return button
    }()

    let editPreviewStyleButton: UIButton = {
       let button = UIButton()
        button.addTarget(self, action: #selector(editPreviewStyle), for: .touchUpInside)
        button.setImage(RevoImages.editPreviewIcon, for: .normal)
        button.isHidden = true
        return button
    }()

    let             switchCamInfoButton: UIButton = {
       let button = UIButton()
        button.addTarget(self, action: #selector(infoButtonPress), for: .touchUpInside)
        button.setImage(RevoImages.infoIcon, for: .normal)
        return button
    }()

    let presentationButton: UIButton = {
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

    let flashButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.flashOffIcon, for:.normal)
        button.addTarget(self, action: #selector(toggleTorchMode), for: .touchUpInside)
        button.addUIBlurEffectWith(effect: UIBlurEffect(style: .light), cornerRadius: 20)
        return button
    }()

    let switchButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.switchPreviews, for:.normal)
        button.addTarget(self, action: #selector(switchPreviews), for: .touchUpInside)
        button.addUIBlurEffectWith(effect: UIBlurEffect(style: .light), cornerRadius: 20)
        return button
    }()

    let exposureButton: UIButton = {
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

    let zoomButton: UIButton = {
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
    }
    
    func configureNotificationObservers() {
        // Observe when new preview style has been saved
        NotificationCenter.default.addObserver(self, selector: #selector(savePreviewStyle), name: NSNotification.Name(rawValue: "savedStyle"), object: nil)

        // Recognising device orientation changes
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    func addGestureRecognisers() {
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

    func configureViews() {
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
        settingsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true

        view.addSubview(editPreviewStyleButton)
        editPreviewStyleButton.translatesAutoresizingMaskIntoConstraints = false
        editPreviewStyleButton.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor, constant: 0).isActive = true
        editPreviewStyleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true

        view.addSubview(            switchCamInfoButton)
                    switchCamInfoButton.translatesAutoresizingMaskIntoConstraints = false
                    switchCamInfoButton.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor, constant: 0).isActive = true
                    switchCamInfoButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true

        view.addSubview(libraryButton)
        libraryButton.translatesAutoresizingMaskIntoConstraints = false
        libraryButton.centerYAnchor.constraint(equalTo: view.bottomAnchor, constant: -80).isActive = true
        libraryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        libraryButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        libraryButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        view.addSubview(cameraSelectionButton)
        cameraSelectionButton.translatesAutoresizingMaskIntoConstraints = false
        cameraSelectionButton.centerYAnchor.constraint(equalTo: libraryButton.centerYAnchor).isActive = true
        cameraSelectionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        cameraSelectionButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        cameraSelectionButton.heightAnchor.constraint(equalToConstant: 40).isActive = true

        view.addSubview(recordingModeButton)
        recordingModeButton.translatesAutoresizingMaskIntoConstraints = false
        recordingModeButton.centerYAnchor.constraint(equalTo: libraryButton.centerYAnchor).isActive = true
        recordingModeButton.leadingAnchor.constraint(equalTo: libraryButton.trailingAnchor, constant: 30).isActive = true
        recordingModeButton.widthAnchor.constraint(equalToConstant: 48).isActive = true

        view.addSubview(presentationButton)
        presentationButton.translatesAutoresizingMaskIntoConstraints = false
        presentationButton.centerYAnchor.constraint(equalTo: libraryButton.centerYAnchor).isActive = true
        presentationButton.trailingAnchor.constraint(equalTo: cameraSelectionButton.leadingAnchor, constant: -30).isActive = true
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
        switchButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        switchButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        switchButton.widthAnchor.constraint(equalToConstant: 40).isActive = true

        view.addSubview(flashButton)
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        flashButton.bottomAnchor.constraint(equalTo: switchButton.topAnchor, constant: -20).isActive = true
        flashButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        flashButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        flashButton.widthAnchor.constraint(equalToConstant: 40).isActive = true

        view.addSubview(exposureButton)
        exposureButton.translatesAutoresizingMaskIntoConstraints = false
        exposureButton.topAnchor.constraint(equalTo: switchButton.bottomAnchor, constant: 20).isActive = true
        exposureButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        exposureButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        exposureButton.widthAnchor.constraint(equalToConstant: 40).isActive = true

        view.addSubview(zoomButton)
        zoomButton.translatesAutoresizingMaskIntoConstraints = false
        zoomButton.topAnchor.constraint(equalTo: exposureButton.bottomAnchor, constant: 20).isActive = true
        zoomButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        zoomButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        zoomButton.widthAnchor.constraint(equalToConstant: 40).isActive = true

        view.addSubview(cameraSettingSlider)
        cameraSettingSlider.translatesAutoresizingMaskIntoConstraints = false

        // Slider is rotated to become a vertical slider
        cameraSettingSlider.transform = CGAffineTransform(rotationAngle: CGFloat.pi * -90 / 180)
        let rotatedHeight: CGFloat = 250

        cameraSettingSlider.topAnchor.constraint(equalTo: switchButton.bottomAnchor, constant: 20).isActive = true
        cameraSettingSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: (rotatedHeight / 2) - 30).isActive = true
        // Rotated the width will act as the sliders height and height as width
        cameraSettingSlider.widthAnchor.constraint(equalToConstant: rotatedHeight).isActive = true
        cameraSettingSlider.heightAnchor.constraint(equalToConstant: 20).isActive = true
//        isoSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
    }

    //MARK: - Record Screen

    @objc func recordButtonTap(tapGesture: UITapGestureRecognizer) {

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

    func startRecord() {
        screenRecorder.isMicrophoneEnabled = true
        screenRecorder.startCapture(handler: { cmSampleBuffer, rpSampleBufferType, error in
            if let error = error {
                print("Error with startCapture: \(error.localizedDescription)")
            } else {
                self.assetWriter.writeBuffer(cmSampleBuffer, rpSampleType: rpSampleBufferType)
            }
        }) { error in
            if error != nil {
                print("Error with startCapture: \(error!.localizedDescription)")
                // Handel
            } else {
                self.recordingButton.animateRecordingButton()
                self.alertMultiViewOfRecordingStart()
                self.animateControlsAlphaTo(0.0)
                self.startRecordingTime()
            }
        }
    }

    func stopRecording() {
        recordingButton.isUserInteractionEnabled = false
        libraryButton.isUserInteractionEnabled = false
        recordingButton.showActivitySpinner()
        print("stopCapture")
        screenRecorder.stopCapture { error in
            print("returned from stop")

            if error != nil {
                print("Error: \(error!.localizedDescription)")
            } else {
                self.assetWriter.finishWriting(completionHandler: { url, error in

                    DispatchQueue.main.async {

                        if error != nil {
                            print("error: \(error!.localizedDescription)")
                        } else if url != nil {
                            print("Recording finished")
                            self.recordingButton.isUserInteractionEnabled = true
                            self.libraryButton.isUserInteractionEnabled = true
                            self.recordingButton.hideActivitySpinner()
                            self.updateLibraryButtonThumbnail()
                        } else {
                            print("Saved crash")
                            self.recordingButton.isUserInteractionEnabled = true
                            self.libraryButton.isUserInteractionEnabled = true
                            self.recordingButton.hideActivitySpinner()
                            self.assetWriter.resetWriter()
                        }
                    }
                })
            }
        }
    }

    var activityVC: RPBroadcastActivityViewController!

    func startBroadcast() {
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

    func stopBroadcast() {
        broadcastVC.finishBroadcast { error in
            if error == nil {
                print("Broadcast ended")
                DispatchQueue.main.async {
                    self.recordingButton.animateRecordingButton()
                    self.alertMultiViewOfRecordingEnd()
                    self.animateControlsAlphaTo(1.0)
                    self.stopRecordingTime()
                }
            }
        }
    }

    func animateControlsAlphaTo(_ newAlpha: CGFloat) {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            self.editPreviewStyleButton.alpha = newAlpha
            self.cameraSelectionButton.alpha = newAlpha
            self.presentationButton.alpha = newAlpha
            self.recordingModeButton.alpha = newAlpha
            self.libraryButton.alpha = newAlpha
        }, completion: nil)
    }


    @objc func changeRecordingPresentation() {
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
            presentationButton.setImage(RevoImages.switchFullScreenPreview, for: .normal)
            delegate?.changePresentationTo(mode: .switchCam)
            editPreviewStyleButton.isHidden = true
                        switchCamInfoButton.isHidden = false
            presentationMode = .switchCam
        }
    }

    @objc func recordingModePress() {
        switch recordingMode {
        case .live:
            recordingModeButton.setImage(RevoImages.cameraIcon(), for: .normal)
            recordingButton.recordingMode = .video
            recordingMode = .video
        case .video:
            recordingModeButton.setImage(RevoImages.liveButtonIcon, for: .normal)
            recordingButton.recordingMode = .live
            recordingMode = .live
        }
    }

    func startRecordingTime() {
        var runCount: Double = 0

        recordingTime = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            runCount += 1
            self.timeLabel.text = Time.asString(from: runCount)
        }
    }

    func stopRecordingTime() {
        recordingTime.invalidate()
        timeLabel.text = Time.asString(from: 0.0)
    }

    @objc func toggleTorchMode() {
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

    @objc func editPreviewStyle() {
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

    @objc func infoButtonPress() {
        let alert = UIAlertController(title: "Switch Mode", message: """
                Switch mode allows you to record footage while seamlessly switching to the front and back camera.

                Both camera's settings may be adjusted independently.
                """, preferredStyle: .alert)
        let action = UIAlertAction(title: "Got it", style: .default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)

    }

    @objc func savePreviewStyle() {
        editPreviewStyleButton.setImage(RevoImages.editPreviewIcon, for: .normal)
        editingMode = .ready
    }


    @objc func cameraSelectionPress(sender: UIButton) {
        // This will check which current camera is selected then toggle to the next available from the devicesAvailable array
        let currentIndex = devicesAvailable.firstIndex(of: sender.titleLabel!.text!)!
        var newIndex = currentIndex + 1

        if newIndex != devicesAvailable.count {
            cameraSelectionButton.setTitle(devicesAvailable[newIndex], for: .normal)
        } else {
            // Current camera is last in the array so toggle back to beginning
            cameraSelectionButton.setTitle(devicesAvailable[0], for: .normal)
            newIndex = 0
        }

        switch newIndex {
        case 0:
            delegate?.cameraSelectionOf(selection: .wide)
        case 1:
            delegate?.cameraSelectionOf(selection: .ultraWide)
        case 2:
            delegate?.cameraSelectionOf(selection: .telephoto)
        default:
            break
        }
    }

    func currentFlashMode() -> AVCaptureDevice.FlashMode {
        let mode: AVCaptureDevice.FlashMode

        switch torchMode {
        case .off:
            mode = .off
        case .on:
            mode = .on
        }
         return mode
    }

    func currentTorchMode() -> AVCaptureDevice.TorchMode {
        let mode: AVCaptureDevice.TorchMode

        switch torchMode {
        case .off:
            mode = .off
        case .on:
            mode = .on
        }
         return mode
    }


    @objc func visitLibraryVC() {
        if torchMode == .on {
            toggleTorchMode()
        }

        let libraryVC = LibraryVC()
        libraryVC.modalPresentationStyle = .fullScreen
        self.present(libraryVC, animated: true, completion: nil)
    }

    @objc func switchPreviews() {
        delegate?.switchPreviewsFor(mode: presentationMode)
        cameraSettingSlider.isHidden = true
    }

    @objc func changeExposure() {
        guard let exposureTargetBiasMinMax = currentCameraExposureTargetBiasMinMax?(),
              let exposureTargetBias = currentCameraExposureTargetBias?() else {
            return
        }
        cameraSettingSlider.minimumValue = exposureTargetBiasMinMax[0]
        cameraSettingSlider.maximumValue = exposureTargetBiasMinMax[1]
        cameraSettingSlider.value = exposureTargetBias
        hideOrShowSliderFor(setting: .exposure)
    }

    @objc func changeZoom() {
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

    @objc func exposureSliderChanged(slider: UISlider, event: UIEvent) {
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
    func hideOrShowSliderFor(setting: CameraSetting) {
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
    func startSliderRemovalTimer() {
        sliderRemovalTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            self.cameraSettingSlider.isHidden = true
        }
    }

    @objc func presentSettings() {
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
            print("cancel")
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
