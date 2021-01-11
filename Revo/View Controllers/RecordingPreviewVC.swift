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


class RecordingPreviewVC: UIViewController {
    
    enum ControlState {
        case visible
        case invisible
    }
    
    var recordingURL: URL?
    
    var controlState: ControlState = .invisible
    
    lazy var player = AVPlayer(url: recordingURL!)
    
    weak var deletionDelegate: RecordingPreviewDelegate?
            
    let recordingOptionsView: RecordingOptionsView = {
        let view = RecordingOptionsView()
        view.deleteButton.addTarget(self, action: #selector(deleteRecording), for: .touchUpInside)
        view.shareButton.addTarget(self, action: #selector(shareRecording), for: .touchUpInside)
        return view
    }()
    
    let topBarView: TopPreviewOptionsView = {
        let view = TopPreviewOptionsView()
        view.backButton.addTarget(self, action: #selector(backButtonPress), for: .touchUpInside)
        view.audioButton.addTarget(self, action: #selector(audioButtonPress), for: .touchUpInside)
        return view
    }()
       
    lazy var playerViewController: AVPlayerViewController = {
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
    
    init(recordingURL: URL) {
        self.recordingURL = recordingURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func configureViews() {
        view.addSubview(playerViewController.view)
        playerViewController.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(playerLayerTap)))
        playerViewController.view.frame = view.bounds
        
        view.addSubview(recordingOptionsView)
        recordingOptionsView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height, width: UIScreen.main.bounds.width, height: 67)
        // Setup the optionsLabel to show the file size of the recording.
        recordingOptionsView.optionsLabel.text = recordingURL!.fileSizeString
        
        view.addSubview(topBarView)
        topBarView.frame = CGRect(x: 0, y: -80, width: UIScreen.main.bounds.width, height: 80)
    }
    
    @objc func playerLayerTap(sender: UITapGestureRecognizer) {
        switch controlState {
        case .visible:
            recordingOptionsView.updatePositionTo(state: .inactive)
            topBarView.updatePositionTo(state: .inactive)
            controlState = .invisible
        case .invisible:
            recordingOptionsView.updatePositionTo(state: .active)
            recordingOptionsView.optionsLabel.isHidden = false
            topBarView.updatePositionTo(state: .active)
            controlState = .visible
        }
        
    }
    
    func addFileCreationDate() {
        guard let date = recordingURL!.creationDate else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM y"
        let dateString = dateFormatter.string(from: date)
        print("should")
        topBarView.dateLabel.text = dateString
    }
    
    // Check to see if user really wants to delete recordings
    @objc func deleteRecording() {
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
    
    func deleteRecordings() {
        deletionDelegate?.removeRecordingWith(url: recordingURL!)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func shareRecording() {
        let activityVC = UIActivityViewController(activityItems: [recordingURL!], applicationActivities: nil)
        DispatchQueue.main.async {
            self.present(activityVC, animated: true)
        }
    }
    
    @objc func replayRecording() {
    
    }
    
    @objc func backButtonPress() {
        recordingOptionsView.isHidden = true
        topBarView.isHidden = true
        dismiss(animated: false, completion: nil)
    }
    
    // Toggles the player's audio on or off
    @objc func audioButtonPress() {
        if player.isMuted {
            player.isMuted = false
            topBarView.setAudioButtonTo(muted: false)
        } else {
            player.isMuted = true
            topBarView.setAudioButtonTo(muted: true)
        }
    }


}
