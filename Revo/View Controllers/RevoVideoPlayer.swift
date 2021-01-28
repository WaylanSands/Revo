//
//  RecordingPreviewVC.swift
//  Revo
//
//  Created by Waylan Sands on 8/12/20.
//

import UIKit
import AVKit

protocol RecordingPreviewDelegate: class {
    func removeRecordingWith(url: URL)
}


class RevoVideoPlayer: UIViewController {
    
    enum ControlState {
        case visible
        case invisible
    }
    
    private var recordingURL: URL?

    private var controlState: ControlState = .invisible
    private lazy var player = AVPlayer(url: recordingURL!)
    weak var deletionDelegate: RecordingPreviewDelegate?
    private var recordingDisplayLink: CADisplayLink!
            
    let recordingOptionsView: RecordingOptionsView = {
        let view = RecordingOptionsView()
        view.deleteButton.addTarget(self, action: #selector(deleteRecording), for: .touchUpInside)
        view.shareButton.addTarget(self, action: #selector(shareRecording), for: .touchUpInside)
        return view
    }()
    
    private let topBarView: TopPreviewOptionsView = {
        let view = TopPreviewOptionsView()
        view.backButton.addTarget(self, action: #selector(backButtonPress), for: .touchUpInside)
        view.audioButton.addTarget(self, action: #selector(audioButtonPress), for: .touchUpInside)
        return view
    }()
    
    private let playPauseButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.pauseIcon, for: .normal)
        button.addTarget(self, action: #selector(playPauseButtonPress), for: .touchUpInside)
        button.alpha = 0
        return button
    }()
       
    private lazy var playerViewController: AVPlayerViewController = {
        let playerView = AVPlayerViewController()
        playerView.videoGravity = .resizeAspect
        playerView.showsPlaybackControls = false
        playerView.player?.volume = 1
        playerView.player = player
        return playerView
    }()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addFileCreationDate()
        configureViews()
        player.play()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        RevoAnalytics.logScreenView(for: "Recording Preview Screen", ofClass: "RecordingPreviewVC")
        NotificationCenter.default.addObserver(self, selector: #selector(playerFinished), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        recordingDisplayLink = CADisplayLink(target: self, selector: #selector(trackPlaybackProgress))
        recordingDisplayLink.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
        recordingDisplayLink.isPaused = false
    }
    
    init(recordingURL: URL) {
        self.recordingURL = recordingURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func configureViews() {
        view.addSubview(playerViewController.view)
        playerViewController.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(playerLayerTap)))
        playerViewController.view.frame = view.bounds
        
        view.addSubview(playPauseButton)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        playPauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.addSubview(recordingOptionsView)
        recordingOptionsView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height, width: UIScreen.main.bounds.width, height: 67)
        // Setup the optionsLabel to show the file size of the recording.
        recordingOptionsView.optionsLabel.text = recordingURL!.fileSizeString
        
        view.addSubview(topBarView)
        topBarView.frame = CGRect(x: 0, y: -80, width: UIScreen.main.bounds.width, height: 80)
    }
    
    private func addFileCreationDate() {
        guard let date = recordingURL!.creationDate else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM y"
        let dateString = dateFormatter.string(from: date)
        topBarView.dateLabel.text = dateString
    }
    
    // Check to see if user really wants to delete recordings
    @objc private func deleteRecording() {
        let alert = UIAlertController(title: "Are you sure?", message: """
                Recordings are removed permanently once deleted.
                """, preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .default) { action in
            self.deleteRecordings()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func deleteRecordings() {
        deletionDelegate?.removeRecordingWith(url: recordingURL!)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func shareRecording() {
        let activityVC = UIActivityViewController(activityItems: [recordingURL!], applicationActivities: nil)
        
        activityVC.completionWithItemsHandler = { activity, success, items, error in
            if !success {
                // Cancelled by the user
                return
            }
            
            guard let activity = activity else { return }
            RevoAnalytics.videoActivityCompletedWith(activity: activity)
        }
        
        DispatchQueue.main.async {
            self.present(activityVC, animated: true)
        }
    }
    
    @objc private func backButtonPress() {
        recordingOptionsView.isHidden = true
        topBarView.isHidden = true
        dismiss(animated: false, completion: nil)
    }
    
    // Toggles the player's audio on or off
    @objc private func audioButtonPress() {
        if player.isMuted {
            player.isMuted = false
            topBarView.setAudioButtonTo(muted: false)
        } else {
            player.isMuted = true
            topBarView.setAudioButtonTo(muted: true)
        }
    }
    
    @objc private func playerLayerTap() {
        
        //The player has finished and controls should remain visible
        if player.currentTime() == player.currentItem?.duration && controlState == .visible {
            return
        }
        
        switch controlState {
        case .visible:
            recordingOptionsView.updatePositionTo(state: .inactive)
            topBarView.updatePositionTo(state: .inactive)
            animatePlayPauseButton(alpha: 0)
            controlState = .invisible
        case .invisible:
            recordingOptionsView.updatePositionTo(state: .active)
            recordingOptionsView.optionsLabel.isHidden = false
            topBarView.updatePositionTo(state: .active)
            animatePlayPauseButton(alpha: 1)
            controlState = .visible
        }
    }
    
    @objc func playPauseButtonPress() {
        if player.timeControlStatus == .playing {
            playPauseButton.setImage(RevoImages.playIcon, for: .normal)
            player.pause()
        } else if player.currentTime() < player.currentItem!.duration {
            playPauseButton.setImage(RevoImages.pauseIcon, for: .normal)
            recordingDisplayLink.isPaused = false
            playerLayerTap()
            player.play()
        } else if player.currentTime() == player.currentItem?.duration {
            playPauseButton.setImage(RevoImages.pauseIcon, for: .normal)
            
            player.seek(to: .zero) { _ in
                self.recordingDisplayLink.isPaused = false
                self.playerLayerTap()
                self.player.play()
            }
        }
        
    }
    
    func animatePlayPauseButton(alpha: CGFloat) {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            self.playPauseButton.alpha = alpha
        }, completion: nil)
    }
    
    @objc func playerFinished() {
        playPauseButton.setImage(RevoImages.playIcon, for: .normal)
        recordingDisplayLink.isPaused = true
        playerLayerTap()
        print("Finished")
    }
    
    @objc func trackPlaybackProgress() {
        let currentTime = player.currentTime().seconds
        let duration = player.currentItem!.duration.seconds
        recordingOptionsView.progressView.progress = Float(currentTime / duration)
        recordingOptionsView.optionsLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .medium)
        recordingOptionsView.optionsLabel.text = Time.asString(from: currentTime)
        recordingOptionsView.progressView.isHidden = false
    }
    
    
    

}
