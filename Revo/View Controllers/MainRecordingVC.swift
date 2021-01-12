//
//  ViewController.swift
//  Revo
//
//  Created by Waylan Sands on 1/12/20.
//

import UIKit
import Photos
import ReplayKit
import AVFoundation

// This is the main UIViewController for screen recording. MainRecordingVC adds a SplitScreenVC as a child view controller
// so SplitScreenVC can handle it's own video PreviewViews. MainRecordingVC also adds a PassThroughWindow (a subclass of UIWindow
// which allows touches to fall to lower UIWindows) as the key window and sets a RecordingControlsVC as the PassThroughWindow's
// rootViewController. This is done so the RecordingControlsVC's RPScreenRecorder will record views on the lower UIWindow which
// MainRecordingVC is contained while ignoring all views of the RecordingControlsVC.

class MainRecordingVC: UIViewController {
    
    private var topWindow: PassThroughWindow?
    private let topWindowRecordingControlsVC = RecordingControlsVC()
    
    // Used when in pip mode
    private var frontFloatingPreviewView = FrontPreviewView()
    private var rearPreviewView = PreviewView()
    
    // Front PreviewView used in switchCam mode
    private let frontFullScreenPreviewView = PreviewView()
    
    // Views for editing different presentation modes
    private let splitStyleView = SplitModeStyleView()
    private let pipStyleView = PipModeStyleView()
    
    private var currentlyRecording = false
    private var pipIsFrontCamera = true
    private var rearDeviceISO: CGFloat?
    
    private var currentRearDevice: AVCaptureDevice!
    private var currentFrontDevice: AVCaptureDevice!
    
    private let captureSession = AVCaptureMultiCamSession()
    private var selectedRearDevice: AVCaptureDevice?
    
    // What are the available built in devices - Duel, Triple or Single
    private var devicesAvailable: DevicesAvailable?
    
    // Preview modes such as pip or split screen
    private var presentationMode: PresentationMode = .switchCam
    
    // splitScreenVC holds its own previewLayers which manages gestures
    private let splitScreenVC = SplitScreenVC()
    
    // AVCaptureVideoPreviewLayers change when switching recordingMode etc split screen
    private lazy var activeRearPreviewLayerLayer: AVCaptureVideoPreviewLayer = rearPreviewView.videoPreviewLayer
    private lazy var activeFrontPreviewLayerLayer: AVCaptureVideoPreviewLayer = frontFloatingPreviewView.videoPreviewLayer
    
    
    private let appLogo: UILabel = {
        let label = UILabel()
        label.text = "revo"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 30, weight: .black)
        label.alpha = 0
        return label
    }()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //MARK: - View did load
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureGestureRecognisers()
        checkAuthStatusForVideo()
        configurePreviewLayers()
        configureSubController()
        configureTopWindow()
        configureDelegates()
        configureClosures()
        configureViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        configureForegroundObserver()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        removeForegroundObserver()
    }
    
    private func configureClosures() {
        // topWindowRecordingControlsVC requests the latest camera values when adjusting exposure and zoom
        topWindowRecordingControlsVC.currentCameraExposureTargetBiasMinMax = self.currentCameraExposureTargetBiasMinToMax
        topWindowRecordingControlsVC.currentCameraExposureTargetBias = self.currentCameraExposureTargetBias
        topWindowRecordingControlsVC.currentCameraMaxZoomFactor = self.currentCameraMaxZoomFactor
        topWindowRecordingControlsVC.currentCameraZoomFactor = self.currentCameraZoomFactor
        topWindowRecordingControlsVC.alertMultiViewOfRecordingStart = self.beginRecording
        topWindowRecordingControlsVC.alertMultiViewOfRecordingEnd = self.endRecording
    }
    
    private func configureDelegates() {
        pipStyleView.styleDelegate = frontFloatingPreviewView
        splitStyleView.styleDelegate = splitScreenVC
    }
    
    private func configureTopWindow() {
        if let currentWindowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            topWindow = PassThroughWindow(windowScene: currentWindowScene)
            topWindowRecordingControlsVC.delegate = self
            topWindow!.rootViewController = topWindowRecordingControlsVC
            topWindow!.windowLevel = .statusBar
            topWindow!.isHidden = false
            topWindow!.makeKeyAndVisible()
        }
    }
    
    private func configureSubController() {
        self.addChild(splitScreenVC)
        self.view.addSubview(splitScreenVC.view)
        splitScreenVC.view.frame = self.view.bounds
        splitScreenVC.didMove(toParent: self)
    }
    
    private func configureGestureRecognisers() {
        view.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(rearPreviewLongPress)))
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(rearPreviewTapped)))
    }
    
    // Observes app moving to foreground so app can check the apps authorisation when user starts or returns to the app.
    private func configureForegroundObserver() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appEnteredForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func removeForegroundObserver() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc private func appEnteredForeground() {
        checkAuthStatusForVideo()
    }
    
    private  func configureViews() {
        // Rear camera preview layer
        view.addSubview(rearPreviewView)
        rearPreviewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        rearPreviewView.videoPreviewLayer.frame = view.bounds
        
        view.addSubview(frontFullScreenPreviewView)
        frontFullScreenPreviewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        frontFullScreenPreviewView.videoPreviewLayer.frame = view.bounds
        frontFullScreenPreviewView.isHidden = true
        
        // Front camera preview layer
        view.addSubview(frontFloatingPreviewView)
        frontFloatingPreviewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        view.addSubview(appLogo)
        appLogo.translatesAutoresizingMaskIntoConstraints = false
        appLogo.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30).isActive = true
        appLogo.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60).isActive = true
    }
    
    // check the app's authorisation status and start cam session if authorised.
    private func checkAuthStatusForVideo() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.setupCaptureSession()
        case .notDetermined:  // App has not requested access for video
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted && AVCaptureMultiCamSession.isMultiCamSupported {
                    self.setupCaptureSession()
                } else if granted && !AVCaptureMultiCamSession.isMultiCamSupported {
                    self.setupCaptureSession()
                } else {
                    // User selected "Don't allow camera access"
                    self.sendToSettingToAllowCameraAccess()
                }
            }
        case .denied:
            self.sendToSettingToAllowCameraAccess()
        case .restricted:
            Alert.showBlockingAlert(title: "Restricted access", message: "Your device's camera access is restricted please change it before proceeding.", vc: self)
        default:
            sendToSettingToAllowCameraAccess()
        }
    }
    
    private func sendToSettingToAllowCameraAccess() {
        DispatchQueue.main.async {
            let message = "In order for revo to function camera access is needed. To allow camera access please toggle the switch within the app's settings"
            let alertController = UIAlertController(title: "Camera access needed", message: message, preferredStyle: .alert)
            let visitSettingsAction = UIAlertAction(title: "Visit settings", style: .default) { _ in
                let url = URL(string:UIApplication.openSettingsURLString)
                if UIApplication.shared.canOpenURL(url!){
                    UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                }
            }
            alertController.addAction(visitSettingsAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func setupCaptureSession() {
        if AVCaptureMultiCamSession.isMultiCamSupported {
            self.setupMultiCamSession()
        } else{
            self.setupSingleCamSession()
        }
    }
    
    private func setupMultiCamSession() {
        captureSession.beginConfiguration()
        currentRearDevice = rearCamera()
        let frontDevice = frontCamera()
        
        do  {
            let  rearDeviceInput = try AVCaptureDeviceInput(device: currentRearDevice!)
            let frontDeviceInput = try AVCaptureDeviceInput(device: frontDevice!)
            
            for each in captureSession.inputs {
                captureSession.removeInput(each)
            }
            
            activeRearPreviewLayerLayer.session = nil
            activeFrontPreviewLayerLayer.session = nil
            
            if captureSession.canAddInput(rearDeviceInput) {
                captureSession.addInput(rearDeviceInput)
            }
            
            if captureSession.canAddInput(frontDeviceInput) {
                captureSession.addInput(frontDeviceInput)
            }
            
            activeRearPreviewLayerLayer.session = captureSession
            activeFrontPreviewLayerLayer.session = captureSession
            
            captureSession.commitConfiguration()
            captureSession.startRunning()
            
        } catch {
            Alert.showBlockingAlert(title: "Device Error", message: error.localizedDescription, vc: self)
        }
    }
    
    // MARK: - Configure for new Presentation Mode
    
    private func configurePreviewLayers() {
        captureSession.beginConfiguration()
        
        activeRearPreviewLayerLayer.session = nil
        activeFrontPreviewLayerLayer.session = nil
        
        switch presentationMode {
        case .switchCam:
            rearPreviewView.videoPreviewLayer.session = captureSession
            frontFullScreenPreviewView.videoPreviewLayer.session = captureSession
            activeRearPreviewLayerLayer = rearPreviewView.videoPreviewLayer
            activeFrontPreviewLayerLayer = frontFullScreenPreviewView.videoPreviewLayer
            frontFullScreenPreviewView.isUserInteractionEnabled = true
            frontFloatingPreviewView.isHidden = true
            rearPreviewView.isHidden = false
        case .pip:
            rearPreviewView.videoPreviewLayer.session = captureSession
            frontFloatingPreviewView.videoPreviewLayer.session = captureSession
            activeRearPreviewLayerLayer = rearPreviewView.videoPreviewLayer
            activeFrontPreviewLayerLayer = frontFloatingPreviewView.videoPreviewLayer
            frontFloatingPreviewView.isHidden = false
            rearPreviewView.isHidden = false
            revertFrontDeviceSettings()
        case .splitScreen:
            splitScreenVC.topPreviewView.videoPreviewLayer.session = captureSession
            splitScreenVC.bottomPreviewView.videoPreviewLayer.session = captureSession
            activeRearPreviewLayerLayer = splitScreenVC.topPreviewView.videoPreviewLayer
            activeFrontPreviewLayerLayer = splitScreenVC.bottomPreviewView.videoPreviewLayer
            // frontFullScreenPreviewView needs to be marked as isUserInteractionEnabled false
            // to allow touches to the splitScreenVC
            frontFullScreenPreviewView.isUserInteractionEnabled = false
            frontFloatingPreviewView.isHidden = true
            rearPreviewView.isHidden = true
        }
        captureSession.commitConfiguration()
    }
    
    /// Version 1 of revo does not allow front device's setting to be changed out
    /// of switchCam mode. Therefore front device should revert to normal when
    /// mode is changed from switchCam.
    private func revertFrontDeviceSettings() {
        guard let device = currentFrontDevice else {
            return
        }
        
        do {
            try device.lockForConfiguration()
            device.setExposureTargetBias(0.0, completionHandler: nil)
            device.videoZoomFactor = 1
            device.unlockForConfiguration()
        } catch {
            Alert.showBasicAlert(title: "Device Error", message: error.localizedDescription, vc: self)
        }
    }
    
    private func setupSingleCamSession() {
        captureSession.beginConfiguration()
        currentRearDevice = rearCamera()
        
        do {
            let backDeviceInput = try AVCaptureDeviceInput(device: currentRearDevice!)
            captureSession.addInput(backDeviceInput)
            
            rearPreviewView.videoPreviewLayer.session = captureSession
            frontFloatingPreviewView.isHidden = true
            
            captureSession.commitConfiguration()
            captureSession.startRunning()
        } catch {
            Alert.showBlockingAlert(title: "Device Error", message: error.localizedDescription, vc: self)
        }
    }
    
    // Used to dynamically setup camera button options from RecordingControlsVC
    private var trippleCameras = ["1", "0.5", "1.5"]
    private var duelCameras = ["1", "0.5",]
    private var singleCamera = ["1"]
    
    private func rearCamera() -> AVCaptureDevice? {
        
        if selectedRearDevice != nil {
            return selectedRearDevice
        }
        
        if let device = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
            topWindowRecordingControlsVC.devicesAvailable = trippleCameras
            return device
        } else if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            topWindowRecordingControlsVC.devicesAvailable = duelCameras
            return device
        } else {
            // Missing expected rear camera device
            topWindowRecordingControlsVC.devicesAvailable = singleCamera
            Alert.showBlockingAlert(title: "Device Error", message: "Revo can not find your rear camera. If the device is not compromised try quitting the app and trying again.", vc: self)
            return nil
        }
    }
    
    private func frontCamera() -> AVCaptureDevice? {
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            currentFrontDevice = device
            return device
        } else {
            Alert.showBlockingAlert(title: "Device Error", message: "Revo can not find your front camera. If the device is not compromised try quitting the app and trying again.", vc: self)
            return nil
        }
    }
    
    private func removeFocusViewIfAnimating() {
        for each in view.subviews {
            if let focusView = each as? FocusAnimationView {
                focusView.removeFromSuperview()
            }
        }
    }
    
    //MARK: - Focusing Gesture Recognisers
    
    @objc private func rearPreviewTapped(sender: UITapGestureRecognizer) {
        let focusPoint = sender.location(in: rearPreviewView)
        let point = rearPreviewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: focusPoint)
        let device = primaryDevice()
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusModeSupported(.autoFocus) && device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = point
                device.focusMode = .continuousAutoFocus
            }
            
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(device.exposureMode) {
                device.exposurePointOfInterest = point
                device.exposureMode = .continuousAutoExposure
                resetExposureSettings()
            }
            
            device.unlockForConfiguration()
            
            // Do not add a FocusAnimationView if recording
            if currentlyRecording {
                return
            }
            
            // If a focus animation is already a subview it will be removed
            removeFocusViewIfAnimating()
            
            let focusView = FocusAnimationView()
            view.addSubview(focusView)
            focusView.frame = CGRect(x: focusPoint.x - 40, y: focusPoint.y - 40, width: 80, height: 80)
            
            switch sender.state {
            case .ended:
                focusView.showFocusFrame()
            default:
                break
            }
        } catch {
            Alert.showBasicAlert(title: "Device Error", message: error.localizedDescription, vc: self)
        }
    }
    
    @objc private func rearPreviewLongPress(sender: UILongPressGestureRecognizer) {
        
        let focusPoint = sender.location(in: rearPreviewView)
        let point = rearPreviewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: focusPoint)
        let device = primaryDevice()
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusModeSupported(.autoFocus) && device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
            }
            
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(device.exposureMode) {
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
                resetExposureSettings()
            }
            
            device.unlockForConfiguration()
            
            if currentlyRecording {
                // Don't add animation
                return
            }
            
            removeFocusViewIfAnimating()
            
            let focusView = FocusAnimationView()
            view.addSubview(focusView)
            focusView.frame = CGRect(x: focusPoint.x - 40, y: focusPoint.y - 40, width: 80, height: 80)
            
            switch sender.state {
            case .began:
                focusView.stopAnimation()
            case .ended:
                focusView.playAnimation()
            default:
                break
            }
        } catch {
            Alert.showBasicAlert(title: "Device Error", message: error.localizedDescription, vc: self)
        }
        
    }
    
    
    @objc private func visitLibraryVC() {
        topWindowRecordingControlsVC.visitLibraryVC()
    }
    
    
    private func currentCameraExposureTargetBiasMinToMax() -> ([Float]) {
        var exposureTargetBias = [Float]()
        let device = primaryDevice()
        
        exposureTargetBias.append(device.minExposureTargetBias)
        exposureTargetBias.append(device.maxExposureTargetBias)
        return exposureTargetBias
    }
    
    private func currentCameraExposureTargetBias() -> Float {
        let device = primaryDevice()
        return device.exposureTargetBias
    }
    
    private func currentCameraMaxZoomFactor() -> CGFloat {
        let device = primaryDevice()
        return device.activeFormat.videoMaxZoomFactor
    }
    
    private func currentCameraZoomFactor() -> CGFloat {
        let device = primaryDevice()
        return device.videoZoomFactor
    }
    
    /// The primary device is the device which consumes the full-screen during pip and switchCam modes.
    /// The currentRearDevice is always the primary device unless frontFullScreenPreviewView isn't hidden and
    /// the presentationMode is set to switchCam.
    private func primaryDevice() -> AVCaptureDevice {
        if presentationMode == .switchCam && !frontFullScreenPreviewView.isHidden {
            return currentFrontDevice
        } else {
            return currentRearDevice
        }
    }
    
    //MARK: - Begin a recoding session
    private func beginRecording() {
        currentlyRecording = true
        checkToAddWatermark()
    }
    
    private func endRecording() {
        currentlyRecording = false
        appLogo.alpha = 0
    }
    
    private func checkToAddWatermark() {
        // Check if user has left an App Store review from app's settings
        let leftAppStoreReview = UserDefaults.standard.bool(forKey: "leftAppStoreReview")
        let userLikesWaterMark = UserDefaults.standard.bool(forKey: "wantsWatermarkShown")
        
        if !leftAppStoreReview || userLikesWaterMark {
            UIView.animate(withDuration: 1, delay: 0.2, options: .curveEaseInOut, animations: {
                self.appLogo.alpha = 1
            }, completion: nil)
        }
    }
    
}


extension MainRecordingVC: ControlsDelegate {
    
    
    func switchPreviewsFor(mode: PresentationMode) {
        switch mode {
        case .splitScreen:
            splitScreenVC.switchPreviews()
        case .pip:
            activeRearPreviewLayerLayer.session = nil
            activeFrontPreviewLayerLayer.session = nil
            
            if pipIsFrontCamera {
                activeFrontPreviewLayerLayer.session = captureSession
                activeRearPreviewLayerLayer.session = captureSession
                pipIsFrontCamera = false
            } else {
                activeRearPreviewLayerLayer.session = captureSession
                activeFrontPreviewLayerLayer.session = captureSession
                pipIsFrontCamera = true
            }
        case .switchCam:
            if frontFullScreenPreviewView.isHidden {
                frontFullScreenPreviewView.isHidden = false
            } else {
                frontFullScreenPreviewView.isHidden = true
            }
        }
    }
    
    func updateCapture(setting: CameraSetting, with slider: UISlider) {
        let device = primaryDevice()
        
        do {
            try device.lockForConfiguration()
            
            switch setting {
            case .exposure:
                device.setExposureTargetBias(slider.value, completionHandler: nil)
            case .zoom:
                device.ramp(toVideoZoomFactor: CGFloat(slider.value), withRate: 4)
            }
            
            device.unlockForConfiguration()
        } catch {
            Alert.showBasicAlert(title: "Device Error", message: error.localizedDescription, vc: self)
        }
    }
    
    func cameraSelectionOf(selection: CameraSelection) {
        switch selection {
        case .wide:
            print("Add Wide")
            selectedRearDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        case .ultraWide:
            print("Add ultraWide")
            selectedRearDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)
        case .telephoto:
            print("Add telephoto")
            selectedRearDevice = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back)
        }
        setupCaptureSession()
    }
    
    // Checks to see which preview user would like to re-style &
    // assigns the appropriate delegate. If called while the
    // previewStyleView is visible it will remove it from the
    // superview as the user had canceled their selection.
    func editPreviewStyleFor(mode: PresentationMode) {
        
        if presentationMode == .pip {
            if topWindowRecordingControlsVC.view.subviews.contains(pipStyleView) {
                pipStyleView.cancelButtonPress()
                pipStyleView.removeFromSuperview()
            } else {
                pipStyleView.frame = view.frame
                topWindowRecordingControlsVC.view.addSubview(pipStyleView)
            }
        } else if presentationMode == .splitScreen {
            if topWindowRecordingControlsVC.view.subviews.contains(splitStyleView) {
                splitStyleView.cancelButtonPress()
                splitStyleView.removeFromSuperview()
            } else {
                splitStyleView.frame = view.frame
                topWindowRecordingControlsVC.view.addSubview(splitStyleView)
            }
        }
    }
    
    
    
    func changePresentationTo(mode: PresentationMode) {
        presentationMode = mode
        configurePreviewLayers()
    }
    
    func changeTorchTo(mode: TorchMode) {
        let torchMode: AVCaptureDevice.TorchMode
        switch mode {
        case .off:
            torchMode = .off
        case .on:
            torchMode = .on
        }
        
        if currentRearDevice.hasTorch {
            do {
                try currentRearDevice.lockForConfiguration()
                currentRearDevice.torchMode = torchMode
                currentRearDevice.unlockForConfiguration()
            } catch {
                Alert.showBasicAlert(title: "Device Error", message: error.localizedDescription, vc: self)
            }
        }
    }
    
    /// Resets the primary devices exposure target bias to zero.
    func resetExposureSettings() {
        primaryDevice().setExposureTargetBias(0, completionHandler: nil)
        topWindowRecordingControlsVC.cameraSettingSlider.isHidden = true
        topWindowRecordingControlsVC.cameraSettingSlider.value = 0
    }
    
}
