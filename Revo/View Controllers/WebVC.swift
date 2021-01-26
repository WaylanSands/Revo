//
//  WebVC.swift
//  Revo
//
//  Created by Waylan Sands on 26/1/21.
//


import UIKit
import WebKit


class WebVC: UIViewController {
    
    
    let webConfiguration: WKWebViewConfiguration = {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        return config
    }()
    
    lazy var webView: WKWebView = {
        let view = WKWebView(frame: .zero, configuration: webConfiguration)
        view.allowsLinkPreview = false
        view.allowsBackForwardNavigationGestures = true
        return view
    }()
    
    let progressView: UIProgressView = {
        let view = UIProgressView()
        view.tintColor = .blue
        view.sizeToFit()
        return view
    }()
    
    var frontFloatingPreviewView = FrontPreviewView()
    
    let topView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
        
    let backButton = UIBarButtonItem(image: UIImage(named: "back_web_icon"), style: .plain, target: self, action: #selector(backPress))
    let forwardButton = UIBarButtonItem(image: UIImage(named: "forward_web_icon"), style: .plain, target: self, action: #selector(forwardPress))
    let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
    let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
    let reloadButton = UIBarButtonItem(image: UIImage(named: "roload_web_icon"), style: .plain, target: self, action: #selector(refreshPress))
    let webButton = UIBarButtonItem(image: RevoImages.webIcon, style: .plain, target: self, action: #selector(dismissWebView))

    let toolbar: UIToolbar = {
        let bar = UIToolbar()
        return bar
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
      return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadInitialRequest()
        configureViews()
    }
    
    private func loadInitialRequest() {
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        let request = URLRequest(url: URL(string: "https://www.google.com")!)
        webView.load(request)
    }

    private func configureViews() {
        view.backgroundColor = .white
        let guide = view.safeAreaLayoutGuide
        
        view.addSubview(topView)
        topView.translatesAutoresizingMaskIntoConstraints = false
        topView.topAnchor.constraint(equalTo: view.topAnchor).isActive =  true
        topView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive =  true
        topView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive =  true
        topView.heightAnchor.constraint(equalToConstant: 80).isActive =  true
        
        view.addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.topAnchor.constraint(equalTo: topView.bottomAnchor).isActive =  true
        progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive =  true
        progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive =  true
        
        view.addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive =  true
        toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive =  true
        toolbar.bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive =  true
        
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: topView.bottomAnchor).isActive =  true
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive =  true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive =  true
        webView.bottomAnchor.constraint(equalTo: toolbar.topAnchor).isActive =  true
        
        view.bringSubviewToFront(progressView)
        
        view.addSubview(frontFloatingPreviewView)
        frontFloatingPreviewView.videoPreviewLayer.videoGravity = .resizeAspectFill
    }
    
    override func viewDidAppear(_ animated: Bool) {
        toolbar.setItems([backButton, fixedSpace, forwardButton, spacer, webButton,fixedSpace, reloadButton], animated: false)
        fixedSpace.width = 40
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.progress = Float(webView.estimatedProgress)
            progressView.isHidden = false
            if progressView.progress == 1 {
                progressView.isHidden = true
            }
        }
    }
    
    
    @objc func dismissVC() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func backPress() {
        webView.goBack()
    }
    
    @objc func forwardPress() {
        webView.goForward()
    }
    
    @objc func refreshPress() {
        webView.reload()
    }
    
    @objc func dismissWebView() {
        dismiss(animated: true, completion: nil)
    }
}

