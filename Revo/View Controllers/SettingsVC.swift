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
        label.text = "Settings".localized
        label.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private lazy var supportButton: UIButton = {
       let button = UIButton()
        button.setTitle("Get support".localized, for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.imageEdgeInsets = UIView.localizedUIEdgeInsets(top: 0, leading: view.frame.width - 40, bottom: 0, trailing: 0)
        button.addTarget(self, action: #selector(getSupport), for: .touchUpInside)
        button.setImage(RevoImages.mailIcon, for: .normal)
        button.contentHorizontalAlignment = .leading
        return button
    }()
    
    private let watermarkButton: UIButton = {
       let button = UIButton()
        button.setTitle("Remove watermark".localized, for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.contentEdgeInsets = UIView.localizedUIEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0)
        button.contentHorizontalAlignment = .leading
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
        button.setTitle("Share the app".localized, for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.imageEdgeInsets = UIView.localizedUIEdgeInsets(top: 0, leading: view.frame.width - 40, bottom: 0, trailing: 0)
        button.addTarget(self, action: #selector(shareApp), for: .touchUpInside)
        button.setImage(RevoImages.blackShareIcon, for: .normal)
        button.contentHorizontalAlignment = .leading
        return button
    }()
    
    private lazy var aboutButton: UIButton = {
       let button = UIButton()
        button.setTitle("About Revo".localized, for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.imageEdgeInsets = UIView.localizedUIEdgeInsets(top: 0, leading: view.frame.width - 40, bottom: 0, trailing: 0)
        button.addTarget(self, action: #selector(aboutRevo), for: .touchUpInside)
        button.setImage(RevoImages.blackAppIcon, for: .normal)
        button.contentHorizontalAlignment = .leading

        return button
    }()
    
    private let versionLabel: UILabel = {
        let label = UILabel()
        label.text = "Version 1.2.3"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        return label
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        title = "Settings"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        RevoAnalytics.logScreenView(for: "Settings Screen", ofClass: "SettingsVC")

        let watermarkIsHidden = UserDefaults.standard.bool(forKey: "watermarkIsHidden")
        
        // Checking whether to toggle on the remove watermark switch for a returning user.
        if watermarkIsHidden {
            removeWatermarkSwitch.isOn = true
        }
    }
    
    private func configureViews() {
        view.backgroundColor = UIColor.systemBackground
        
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
        supportButtonUnderlineView.backgroundColor = .separator
        supportButton.addSubview(supportButtonUnderlineView)
        
        view.addSubview(watermarkButton)
        watermarkButton.translatesAutoresizingMaskIntoConstraints = false
        watermarkButton.topAnchor.constraint(equalTo: supportButton.bottomAnchor, constant: 1).isActive = true
        watermarkButton.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        watermarkButton.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        watermarkButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let watermarkButtonUnderlineView = UIView(frame: CGRect(x: 15, y: 50, width: view.frame.width, height: 1))
        watermarkButtonUnderlineView.backgroundColor = .separator
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
        shareButtonUnderlineView.backgroundColor = .separator
        shareButton.addSubview(shareButtonUnderlineView)
        
        view.addSubview(aboutButton)
        aboutButton.translatesAutoresizingMaskIntoConstraints = false
        aboutButton.topAnchor.constraint(equalTo: shareButton.bottomAnchor, constant: 1).isActive = true
        aboutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        aboutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        aboutButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let aboutButtonUnderlineView = UIView(frame: CGRect(x: 15, y: 50, width: view.frame.width, height: 1))
        aboutButtonUnderlineView.backgroundColor = .separator
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
                let alert = UIAlertController(title: "Revo Support".localized, message: "mail_not_configured".localized, preferredStyle: .alert)
                let dismissAction = UIAlertAction(title: "Dimiss".localized, style: .default)
                alert.addAction(dismissAction)
                self.present(alert, animated: true, completion: nil)
            }
    }
    
    @objc private func watermarkToggled(watermarkSwitch: UISwitch) {
        let promptedToLeaveReview = UserDefaults.standard.bool(forKey: "promptedToLeaveReview")

        if watermarkSwitch.isOn && !promptedToLeaveReview {
            // User has switched on the switch indicating to remove the watermark.
            UserDefaults.standard.setValue(true, forKey: "promptedToLeaveReview")
            UserDefaults.standard.setValue(true, forKey: "watermarkIsHidden")
            
            RevoAnalytics.logWatermarkRemoval()
            
            let alert = UIAlertController(title: "Remove Watermark".localized, message: "watermark_removal_message".localized, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Dismiss".localized, style: .cancel)
            let reviewAction = UIAlertAction(title: "Leave Review".localized, style: .default) { _ in
                // User has selected to leave a review
                // Take user to the revo app on the App Store
                if let writeReviewURL = URL(string: "https://apps.apple.com/app/id1547580951?action=write-review") {
                    UIApplication.shared.open(writeReviewURL, options: [:])
                    RevoAnalytics.logAppStoreReview()
                }
            }
            alert.addAction(cancelAction)
            alert.addAction(reviewAction)
            self.present(alert, animated: true, completion: nil)
        } else if !watermarkSwitch.isOn {
            // The switch has been turned off after being prompted to leave a review
            UserDefaults.standard.setValue(false, forKey: "watermarkIsHidden")
        } else if watermarkSwitch.isOn {
            // The switch has been turned back on after being prompted to leave a review
            UserDefaults.standard.setValue(true, forKey: "watermarkIsHidden")
        }
    }
    
    @objc private func aboutRevo() {
        let alert = UIAlertController(title: "About Revo".localized, message: "about_revo_message".localized, preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Dismiss".localized, style: .default)
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
        
        activityVC.completionWithItemsHandler = { activity, success, items, error in
            if !success {
                // Cancelled by the user
                return
            }
            
            guard let activity = activity else { return }
            RevoAnalytics.linkActivityCompletedWith(activity: activity)
        }
        
        present(activityVC, animated: true)
    }
    
}

extension SettingsVC: MFMailComposeViewControllerDelegate {
   
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
}
