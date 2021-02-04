//
//  UploadVC.swift
//  Revo
//
//  Created by Waylan Sands on 31/1/21.
//


import UIKit
import AVKit
import MobileCoreServices

class UploadVC: UIViewController {
    
    private var recordingURL: URL?
    var player: AVPlayer!
            
    private lazy var playerVC: AVPlayerViewController = {
        let playerView = AVPlayerViewController()
        playerView.videoGravity = .resizeAspectFill
        playerView.showsPlaybackControls = false
        playerView.view.backgroundColor = .black
        playerView.player?.volume = 1
        return playerView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureObservers()
        configureViews()
        view.backgroundColor = .blue
    }
    
    private func configureObservers() {
        // Record when the AVPlayer finishes playing an asset.
        NotificationCenter.default.addObserver(self, selector: #selector(playerFinished), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        // Recognising device orientation changes
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc func orientationChanged() {
        let deviceOrientation = UIDevice.current.orientation
        var angle: Double = 0.0
        
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
        let transform = CGAffineTransform(rotationAngle: CGFloat(angle))
        
        playerVC.view.transform = transform
        playerVC.view.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
    }
    
    private func configureViews() {
        view.addSubview(playerVC.view)
        playerVC.view.frame = view.bounds
    }
    
    func configurePlayerWith(url: URL) {
        player = AVPlayer(url: url)
        playerVC.videoGravity = .resizeAspectFill
        playerVC.player = player
    }
    
    func pausePlayer() {
        if let player = player  {
            player.pause()
            clearMedia()
        }
    }
    
    @objc func playerFinished() {
        // Alert the RecordingControlsVC to update the playButton image
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "playerFinished"), object: nil)
    }
    
    @objc func playButtonTapped() {
        if player.timeControlStatus == .playing {
            // Player has been started and is playing.
            player.pause()
        } else if player.currentTime() < player.currentItem!.duration {
            // Player has been was either paused or not yet started.
            player.play()
        } else if player.currentTime() == player.currentItem!.duration {
            // The video had reached the end of it's duration.
            // We set the player to play from the beginning again
            player.seek(to: .zero) { _ in
                self.player.play()
            }
        }
    }
    
    @objc func toggleVideoGravity() {
        switch playerVC.videoGravity {
        case .resizeAspect:
            playerVC.videoGravity = .resizeAspectFill
        case .resizeAspectFill:
            playerVC.videoGravity = .resizeAspect
        default:
            break
        }

    }
    
    @objc func muteButtonTapped() {
        if player.isMuted {
            player.isMuted = false
        } else {
            player.isMuted = true
        }
    }

    
    func clearMedia() {
        // Clear the media of previous uploads
        playerVC.player = nil
    }


}

