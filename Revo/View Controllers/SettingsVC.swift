//
//  SettingsTableVC.swift
//  revo
//
//  Created by Waylan Sands on 7/1/21.
//

import UIKit
import StoreKit
import MessageUI

class SettingsVC: UIViewController {
    
   private let downArrowButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.blackDownArrow, for: .normal)
        button.addTarget(self, action: #selector(downArrowPress), for: .touchUpInside)
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Settings"
        label.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        label.textColor = RevoColor.blackText
        label.textAlignment = .center
        return label
    }()
    
    private lazy var supportButton: UIButton = {
       let button = UIButton()
        button.setTitle("Get Support", for: .normal)
        button.setTitleColor(RevoColor.blackText, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: view.frame.width - 40, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(getSupport), for: .touchUpInside)
        button.setImage(RevoImages.mailIcon, for: .normal)
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    private let watermarkButton: UIButton = {
       let button = UIButton()
        button.setTitle("Remove watermark", for: .normal)
        button.setTitleColor(RevoColor.blackText, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    private let removeWatermarkSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = .black
        toggle.addTarget(self, action: #selector(watermarkToggled), for: .valueChanged)
        return toggle
    }()
    
    private lazy var shareButton: UIButton = {
       let button = UIButton()
        button.setTitle("Share the app", for: .normal)
        button.setTitleColor(RevoColor.blackText, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: view.frame.width - 40, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(shareApp), for: .touchUpInside)
        button.setImage(RevoImages.blackShareIcon, for: .normal)
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    private lazy var aboutButton: UIButton = {
       let button = UIButton()
        button.setTitle("About revo", for: .normal)
        button.setTitleColor(RevoColor.blackText, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: view.frame.width - 40, bottom: 0, right: 0)
        button.setImage(RevoImages.blackAppIcon, for: .normal)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(aboutRevo), for: .touchUpInside)
        return button
    }()
    
    private let versionLabel: UILabel = {
        let label = UILabel()
        label.text = "Version 1.0.1"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.black.withAlphaComponent(0.3)
        label.textAlignment = .center
        return label
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        title = "Settings"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let leftAppStoreReview = UserDefaults.standard.bool(forKey: "leftAppStoreReview")
        let userLikesWaterMark = UserDefaults.standard.bool(forKey: "wantsWatermarkShown")
        
        // Checking whether to toggle on the remove watermark switch for a returning
        // user if they both don't like the watermark and have left a review.
        if !userLikesWaterMark && leftAppStoreReview  {
            removeWatermarkSwitch.isOn = true
        }
    }
    
    private func configureViews() {
        view.backgroundColor = .white
        
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        view.addSubview(downArrowButton)
        downArrowButton.translatesAutoresizingMaskIntoConstraints = false
        downArrowButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 30).isActive = true
        downArrowButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        
        view.addSubview(supportButton)
        supportButton.translatesAutoresizingMaskIntoConstraints = false
        supportButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
        supportButton.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        supportButton.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        supportButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let supportButtonUnderlineView = UIView(frame: CGRect(x: 15, y: 50, width: view.frame.width, height: 1))
        supportButtonUnderlineView.backgroundColor = UIColor.black
        supportButton.addSubview(supportButtonUnderlineView)
        
        view.addSubview(watermarkButton)
        watermarkButton.translatesAutoresizingMaskIntoConstraints = false
        watermarkButton.topAnchor.constraint(equalTo: supportButton.bottomAnchor, constant: 1).isActive = true
        watermarkButton.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        watermarkButton.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        watermarkButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let watermarkButtonUnderlineView = UIView(frame: CGRect(x: 15, y: 50, width: view.frame.width, height: 1))
        watermarkButtonUnderlineView.backgroundColor = UIColor.black
        watermarkButton.addSubview(watermarkButtonUnderlineView)
        
        watermarkButton.addSubview(removeWatermarkSwitch)
        removeWatermarkSwitch.translatesAutoresizingMaskIntoConstraints = false
        removeWatermarkSwitch.centerYAnchor.constraint(equalTo: watermarkButton.centerYAnchor).isActive = true
        removeWatermarkSwitch.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        
        view.addSubview(shareButton)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.topAnchor.constraint(equalTo: watermarkButton.bottomAnchor, constant: 1).isActive = true
        shareButton.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        shareButton.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        shareButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let shareButtonUnderlineView = UIView(frame: CGRect(x: 15, y: 50, width: view.frame.width, height: 1))
        shareButtonUnderlineView.backgroundColor = UIColor.black
        shareButton.addSubview(shareButtonUnderlineView)
        
        view.addSubview(aboutButton)
        aboutButton.translatesAutoresizingMaskIntoConstraints = false
        aboutButton.topAnchor.constraint(equalTo: shareButton.bottomAnchor, constant: 1).isActive = true
        aboutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        aboutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        aboutButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let aboutButtonUnderlineView = UIView(frame: CGRect(x: 15, y: 50, width: view.frame.width, height: 1))
        aboutButtonUnderlineView.backgroundColor = UIColor.black
        aboutButton.addSubview(aboutButtonUnderlineView)
        
        view.addSubview(versionLabel)
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -70).isActive = true
        versionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        versionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    }
    
    @objc private func getSupport() {
            if MFMailComposeViewController.canSendMail() {
                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = self
                mail.setToRecipients(["waylansands@gmail.com"])
                mail.setMessageBody("<p>Hello, I have a support question regarding Revo.</p>", isHTML: true)

                present(mail, animated: true)
            } else {
                // Mail is not setup for user
                let alert = UIAlertController(title: "Revo Support", message: """
                    It looks like your mail account isn't configured to send mail from the app.

                    If you have any support enquires please shoot them through to waylansands@gmail.com"
                    """, preferredStyle: .alert)
                let dismissAction = UIAlertAction(title: "Dimiss", style: .default)
                alert.addAction(dismissAction)
                self.present(alert, animated: true, completion: nil)
            }
    }
    
    @objc private func watermarkToggled(watermarkSwitch: UISwitch) {
        let leftAppStoreReview = UserDefaults.standard.bool(forKey: "leftAppStoreReview")

        if watermarkSwitch.isOn && !leftAppStoreReview {
            // User has switched on the switch indicating to remove the watermark.
            let alert = UIAlertController(title: "Remove Watermark", message: """
                Revo relies on an honour based system where we ask you to leave a short review on the Appstore.

                After leaving a review the watermark will no longer be present when recording 🤘🏼
                """, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                // Incase anyone does not want to leave a review.
                watermarkSwitch.isOn = false
            }
            let reviewAction = UIAlertAction(title: "Leave Review", style: .default) { _ in
                // User has selected to leave a review
                if let writeReviewURL = URL(string: "https://apps.apple.com/app/id1499893273?action=write-review") {
                    UIApplication.shared.open(writeReviewURL, options: [:]) { success in
                        // Track that user has been successful in landing on the leave review page
                        // The watermark will be no longer be present if successful.
                        UserDefaults.standard.setValue(success, forKey: "leftAppStoreReview")
                    }
                }
            }
            alert.addAction(cancelAction)
            alert.addAction(reviewAction)
            self.present(alert, animated: true, completion: nil)
        } else if !watermarkSwitch.isOn && leftAppStoreReview {
            // The switch has been turned off after leaving a review
            UserDefaults.standard.setValue(true, forKey: "wantsWatermarkShown")
        } else if watermarkSwitch.isOn && leftAppStoreReview {
            // The switch has been turned back on after leaving a review and turning it off
            UserDefaults.standard.setValue(false, forKey: "wantsWatermarkShown")
        }
    }
    
    @objc private func aboutRevo() {
            let alert = UIAlertController(title: "About Revo", message: """
                Revo was created as an educational project to further explore Apple's AVFoundation framework.

                As the app uses relatively new components it is only supported on devices XS, XS Max, XR and later running on iOS 14.
                
                If you enjoy the app or would like to offer any feedback please leave a review on the Appstore.
                """, preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Dismiss", style: .default)
            alert.addAction(deleteAction)
            present(alert, animated: true, completion: nil)
    }
    
    @objc private func downArrowPress() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func shareApp() {
        let items: [Any] = ["Take a look at this neat video app, you can switch between cameras while recording!", URL(string: "https://apps.apple.com/us/app/revo-reverse-video/id1547580951")!]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityVC.excludedActivityTypes = [.copyToPasteboard, .addToReadingList]
        present(activityVC, animated: true)
    }
    
}

extension SettingsVC: MFMailComposeViewControllerDelegate {
   
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
}
