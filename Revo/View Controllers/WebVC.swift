//
//  WebVC.swift
//  Revo
//
//  Created by Waylan Sands on 26/1/21.
//


import UIKit
import WebKit

class WebVC: UIViewController {

    var frontFloatingPreviewView = FrontPreviewView()
    private var controlsAreHidden = true
    var currentlyRecording = false
    
    private let webConfiguration: WKWebViewConfiguration = {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        return config
    }()
    
    lazy var wkWebView: WKWebView = {
        let view = WKWebView(frame: .zero, configuration: webConfiguration)
        view.allowsLinkPreview = false
        view.allowsBackForwardNavigationGestures = true
        return view
    }()
    
    private let progressView: UIProgressView = {
        let view = UIProgressView()
        view.tintColor = .blue
        view.sizeToFit()
        return view
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00:00"
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 19, weight: .semibold)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    
    private let topView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private let dismissButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.whiteDownArrow, for: .normal)
        button.addTarget(self, action: #selector(dismissWebView), for: .touchUpInside)
        return button
    }()
    
    private let controlsButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.hideControls, for: .normal)
        button.addTarget(self, action: #selector(toggleControlVisibility), for: .touchUpInside)
        return button
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
      return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadInitialRequest()
        configureDelegate()
        configureViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        RevoAnalytics.logScreenView(for: "Web Mode Screen", ofClass: "WebVC")
    }
    
    private func configureDelegate() {
        wkWebView.navigationDelegate = self
    }

    private func loadInitialRequest() {
        wkWebView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        let request = URLRequest(url: URL(string: "https://www.google.com")!)
        wkWebView.load(request)
    }

    private func configureViews() {
        view.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.centerYAnchor.constraint(equalTo: view.topAnchor, constant: 55).isActive = true
        timeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        timeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        view.addSubview(topView)
        topView.translatesAutoresizingMaskIntoConstraints = false
        topView.topAnchor.constraint(equalTo: view.topAnchor).isActive =  true
        topView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive =  true
        topView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive =  true
        
        if UIScreen.main.nativeBounds.height > 1334 {
            topView.heightAnchor.constraint(equalToConstant: 80).isActive =  true
        } else {
            // Device is an iPhone SE, 6S, 7 , 8 or smaller
            topView.heightAnchor.constraint(equalToConstant: 60).isActive =  true
        }
        
        topView.addSubview(dismissButton)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.bottomAnchor.constraint(equalTo: topView.bottomAnchor, constant: -10).isActive = true
        dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive =  true
        
        topView.addSubview(controlsButton)
        controlsButton.translatesAutoresizingMaskIntoConstraints = false
        controlsButton.bottomAnchor.constraint(equalTo: topView.bottomAnchor, constant: -5).isActive = true
        controlsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        controlsButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        controlsButton.widthAnchor.constraint(equalToConstant: 40).isActive = true

        view.addSubview(wkWebView)
        wkWebView.translatesAutoresizingMaskIntoConstraints = false
        wkWebView.topAnchor.constraint(equalTo: topView.bottomAnchor).isActive =  true
        wkWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive =  true
        wkWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive =  true
        wkWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive =  true
        
        view.addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.topAnchor.constraint(equalTo: topView.bottomAnchor).isActive =  true
        progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive =  true
        progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive =  true
        
        view.addSubview(frontFloatingPreviewView)
        frontFloatingPreviewView.frame = CGRect(x: (UIScreen.main.bounds.width / 2) - 100, y: (UIScreen.main.bounds.height / 2), width: 200, height: 200)
        frontFloatingPreviewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        frontFloatingPreviewView.frameStyle = .circular
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.progress = Float(wkWebView.estimatedProgress)
            progressView.isHidden = false
            if progressView.progress == 1 {
                progressView.isHidden = true
            }
        }
    }
    
    @objc private func toggleControlVisibility() {
        if controlsAreHidden {
            controlsButton.setImage(RevoImages.showControls, for: .normal)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "animateWebToolBarUp"), object: nil)
            controlsAreHidden = false
        } else {
            controlsButton.setImage(RevoImages.hideControls, for: .normal)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "animateWebToolBarDown"), object: nil)
            controlsAreHidden = true
        }
    }
    
    @objc private func dismissWebView() {
        if currentlyRecording {
            Alert.showBasicAlert(title: "Current Recording", message: "You're currently in a recording session, stop the session first if you would like to leave.", vc: self)
        } else {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "animateWebToolBarDown"), object: nil)
            dismiss(animated: true, completion: nil)
            loadInitialRequest()
        }
    }
    
}

extension WebVC: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("didFailProvisionalNavigation \(error.localizedDescription)")
    }

}
