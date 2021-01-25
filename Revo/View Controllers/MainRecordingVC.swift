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
    
    private let multiCamSession = AVCaptureMultiCamSession()
    private let singleCamSession = AVCaptureSession()
    private var selectedRearDevice: AVCaptureDevice?
    
    enum ActiveSingleCamera {
        case front
        case rear
    }
    
    // Set when device does not support AVCaptureMultiCamSession
    private var activeSingleCam: ActiveSingleCamera?
    
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
        discoverDevices()
        configureViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        RevoAnalytics.logScreenView(for: "Main recording Screen", ofClass: "MainRecordingVC")
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
        
        // Needs to be set as true because frontFullScreenPreviewView is hidden.
        // configurePreviewLayers() is ran before configureViews which would of set it to false
        topWindowRecordingControlsVC.cameraSelectionButton.isUserInteractionEnabled = true
        
        // Front camera preview layer
        view.addSubview(frontFloatingPreviewView)
        frontFloatingPreviewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        // appLogo will animate alpha during recording if remove the
        // watermark switch is off in settings.
        view.addSubview(appLogo)
        appLogo.translatesAutoresizingMaskIntoConstraints = false
        appLogo.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30).isActive = true
        appLogo.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60).isActive = true
    }
    
    // check the app's authorisation status and start cam session if authorised.
    private func checkAuthStatusForVideo() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setupCaptureSession()
                } else {
                    // User selected "Don't allow camera access"
                    self.sendToSettingToAllowCameraAccess()
                }
            }
        case .denied:
            self.sendToSettingToAllowCameraAccess()
        case .restricted:
            Alert.showBlockingAlert(title: "Restricted Access".localized, message: "restricted_access_message".localized, vc: self)
        default:
            sendToSettingToAllowCameraAccess()
        }
    }
    
    private func sendToSettingToAllowCameraAccess() {
        DispatchQueue.main.async {
            let message = "send_to_settings_message".localized
            let alertController = UIAlertController(title: "Camera access needed".localized, message: message, preferredStyle: .alert)
            let visitSettingsAction = UIAlertAction(title: "Visit settings".localized, style: .default) { _ in
                let url = URL(string:UIApplication.openSettingsURLString)
                if UIApplication.shared.canOpenURL(url!){
                    UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                }
            }
            alertController.addAction(visitSettingsAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // Check to see if a AVCaptureMultiCamSession is supported by the device
    // if not a regular AVCaptureSession will be ran. The topWindowRecordingControlsVC
    // will also check if isMultiCamSupported and hide any buttons which expose
    // multi-cam features.
    private func setupCaptureSession() {
        DispatchQueue.main.async {
            if AVCaptureMultiCamSession.isMultiCamSupported {
                self.setupMultiCamSession()
            } else{
                self.setupSingleCamSessionFor(cameraPosition: .back)
            }
        }
    }
    
    
    private func discoverDevices() {
        // The correct array is passed to the topWindowRecordingControlsVC so that
        // the topWindowRecordingControlsVC can display the right set of camera options
        let tripleCameras = ["1", "0.5", "1.5"]
        let duelWideCameras = ["1", "0.5"]
        let duelTeleCameras = ["1", "1.5"]
        let singleCamera = ["1"]
        
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTripleCamera, .builtInDualCamera,.builtInDualWideCamera],
                                                                mediaType: .video, position: .back)
        
        if discoverySession.devices.isEmpty {
            topWindowRecordingControlsVC.cameraSelectionButton.isHidden = true
            topWindowRecordingControlsVC.devicesAvailable = singleCamera
        }
        
        discoverySession.devices.forEach { (device) in
            switch device.deviceType {
            case .builtInTripleCamera:
                topWindowRecordingControlsVC.devicesAvailable = tripleCameras
            case .builtInDualWideCamera:
                topWindowRecordingControlsVC.devicesAvailable = duelWideCameras
            case .builtInDualCamera:
                topWindowRecordingControlsVC.devicesAvailable = duelTeleCameras
            default:
                break
            }
        }
        
    }
    
    //MARK: - Set up multi-cam capture session
    
    private func setupMultiCamSession() {
        multiCamSession.beginConfiguration()
        currentFrontDevice = frontCamera()
        currentRearDevice = rearCamera()
        
        do  {
            let rearDeviceInput = try AVCaptureDeviceInput(device: currentRearDevice!)
            let frontDeviceInput = try AVCaptureDeviceInput(device: currentFrontDevice!)
            
            for each in multiCamSession.inputs {
                multiCamSession.removeInput(each)
            }
            
            activeRearPreviewLayerLayer.session = nil
            activeFrontPreviewLayerLayer.session = nil
            
            if multiCamSession.canAddInput(rearDeviceInput) {
                multiCamSession.addInput(rearDeviceInput)
            }
            
            if multiCamSession.canAddInput(frontDeviceInput) {
                multiCamSession.addInput(frontDeviceInput)
            }
            
            activeRearPreviewLayerLayer.session = multiCamSession
            activeFrontPreviewLayerLayer.session = multiCamSession
            
            multiCamSession.commitConfiguration()
            multiCamSession.startRunning()
            
        } catch {
            Alert.showBlockingAlert(title: "Device Error".localized, message: error.localizedDescription, vc: self)
        }
    }
    
    //MARK: - Set up single-cam capture session
    
    private func setupSingleCamSessionFor(cameraPosition: AVCaptureDevice.Position) {
        singleCamSession.beginConfiguration()
        var device: AVCaptureDevice!
        
        if cameraPosition == .back {
            device = rearCamera()
            currentRearDevice = device
            activeSingleCam = .rear
        } else {
            device = frontCamera()
            currentFrontDevice = device
            activeSingleCam = .front
        }
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: device)
            
            for each in singleCamSession.inputs {
                singleCamSession.removeInput(each)
            }
            
            singleCamSession.addInput(deviceInput)
            activeRearPreviewLayerLayer.session = nil
            
            rearPreviewView.videoPreviewLayer.session = singleCamSession
            frontFloatingPreviewView.isHidden = true
            
            singleCamSession.commitConfiguration()
            singleCamSession.startRunning()
        } catch {
            Alert.showBlockingAlert(title: "Device Error".localized, message: error.localizedDescription, vc: self)
        }
    }
    
    // MARK: - Configure for new Presentation Mode
    
    private func configurePreviewLayers() {
        multiCamSession.beginConfiguration()
        
        activeRearPreviewLayerLayer.session = nil
        activeFrontPreviewLayerLayer.session = nil
        
        switch presentationMode {
        case .switchCam:
            rearPreviewView.videoPreviewLayer.session = multiCamSession
            frontFullScreenPreviewView.videoPreviewLayer.session = multiCamSession
            activeRearPreviewLayerLayer = rearPreviewView.videoPreviewLayer
            activeFrontPreviewLayerLayer = frontFullScreenPreviewView.videoPreviewLayer
            frontFullScreenPreviewView.isUserInteractionEnabled = true
            frontFloatingPreviewView.isHidden = true
            rearPreviewView.isHidden = false
            // Stop cameraSelectionButton from interaction if returning to switchCam with
            // frontFullScreenPreviewView showing.
            if  !frontFullScreenPreviewView.isHidden {
                topWindowRecordingControlsVC.cameraSelectionButton.isUserInteractionEnabled = false
            }
        case .pip:
            rearPreviewView.videoPreviewLayer.session = multiCamSession
            frontFloatingPreviewView.videoPreviewLayer.session = multiCamSession
            activeRearPreviewLayerLayer = rearPreviewView.videoPreviewLayer
            activeFrontPreviewLayerLayer = frontFloatingPreviewView.videoPreviewLayer
            // cameraSelectionButton is re-enabled when switching modes incase it was left off during switchCam
            topWindowRecordingControlsVC.cameraSelectionButton.isUserInteractionEnabled = true
            frontFloatingPreviewView.isHidden = false
            rearPreviewView.isHidden = false
            revertFrontDeviceSettings()
        case .splitScreen:
            splitScreenVC.topPreviewView.videoPreviewLayer.session = multiCamSession
            splitScreenVC.bottomPreviewView.videoPreviewLayer.session = multiCamSession
            activeRearPreviewLayerLayer = splitScreenVC.topPreviewView.videoPreviewLayer
            activeFrontPreviewLayerLayer = splitScreenVC.bottomPreviewView.videoPreviewLayer
            // frontFullScreenPreviewView needs to be marked as isUserInteractionEnabled false
            // to allow touches to the splitScreenVC
            topWindowRecordingControlsVC.cameraSelectionButton.isUserInteractionEnabled = true
            frontFullScreenPreviewView.isUserInteractionEnabled = false
            frontFloatingPreviewView.isHidden = true
            rearPreviewView.isHidden = true
        }
        multiCamSession.commitConfiguration()
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
            Alert.showBasicAlert(title: "Device Error".localized, message: error.localizedDescription, vc: self)
        }
    }
    
    private func rearCamera() -> AVCaptureDevice? {
        if selectedRearDevice != nil {
            return selectedRearDevice
        }
        
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return device
        } else {
            // Missing expected rear device
            Alert.showBlockingAlert(title: "Device Error".localized, message: "cant_find_rear_camera".localized, vc: self)
            return nil
        }
    }
    
    private func frontCamera() -> AVCaptureDevice? {
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            return device
        } else {
            // Missing expected front device
            Alert.showBlockingAlert(title: "Device Error".localized, message: "cant_find_front_camera".localized, vc: self)
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
            Alert.showBasicAlert(title: "Device Error".localized, message: error.localizedDescription, vc: self)
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
            Alert.showBasicAlert(title: "Device Error".localized, message: error.localizedDescription, vc: self)
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
    
    /// The primary device is used to determine which device to modify when the
    /// user chooses to change camera settings such as exposure or zoom.
    /// The device which consumes the screen during pip and switchCam modes when
    /// running a multi-cam session is the primary device.
    /// When running a single-cam session we need to check the activeSingleCam
    /// to help determine which camera the user is using.
    private func primaryDevice() -> AVCaptureDevice {
        if presentationMode == .switchCam && !frontFullScreenPreviewView.isHidden {
            return currentFrontDevice
        } else if singleCamSession.isRunning && activeSingleCam == .rear {
            return currentRearDevice
        } else if singleCamSession.isRunning && activeSingleCam == .front {
            return currentFrontDevice
        } else {
            return currentRearDevice
            // When none of these conditions is met we return the currentRearDevice.
            // This limits the user to only being able to zoom and change exposure of
            // the rear camera when not in switchCam mode. This may be updated in future versions.
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
        let watermarkIsHidden = UserDefaults.standard.bool(forKey: "watermarkIsHidden")
        
        if !watermarkIsHidden {
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
                activeFrontPreviewLayerLayer.session = multiCamSession
                activeRearPreviewLayerLayer.session = multiCamSession
                pipIsFrontCamera = false
            } else {
                activeRearPreviewLayerLayer.session = multiCamSession
                activeFrontPreviewLayerLayer.session = multiCamSession
                pipIsFrontCamera = true
            }
        case .switchCam:
            // Toggling cameras while running multiCamSession is just a matter of
            // showing and hiding the frontFullScreenPreviewView.
            // Toggling cameras while in singleCamSession requires the correct
            // single-cam session to be set up.
            if frontFullScreenPreviewView.isHidden && multiCamSession.isRunning {
                // cameraSelectionButton is disabled as the user can not toggle front facing cameras
                topWindowRecordingControlsVC.cameraSelectionButton.isUserInteractionEnabled = false
                frontFullScreenPreviewView.isHidden = false
            } else if !frontFullScreenPreviewView.isHidden && multiCamSession.isRunning {
                // cameraSelectionButton is reenabled when switching to the rear camera
                topWindowRecordingControlsVC.cameraSelectionButton.isUserInteractionEnabled = true
                frontFullScreenPreviewView.isHidden = true
            } else if singleCamSession.isRunning && activeSingleCam == .front {
                setupSingleCamSessionFor(cameraPosition: .back)
            } else if singleCamSession.isRunning && activeSingleCam == .rear {
                setupSingleCamSessionFor(cameraPosition: .front)
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
            Alert.showBasicAlert(title: "Device Error".localized, message: error.localizedDescription, vc: self)
        }
    }
    
    func cameraSelectionOf(selection: CameraSelection) {
        switch selection {
        case .wide:
            selectedRearDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        case .ultraWide:
            selectedRearDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)
        case .telephoto:
            selectedRearDevice = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back)
        }
        
        if AVCaptureMultiCamSession.isMultiCamSupported {
            setupCaptureSession()
        } else {
            setupSingleCamSessionFor(cameraPosition: .back)
        }

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
                Alert.showBasicAlert(title: "Device Error".localized, message: error.localizedDescription, vc: self)
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
