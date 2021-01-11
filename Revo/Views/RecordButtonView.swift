//
//  RecordButtonView.swift
//  Revo
//
//  Created by Waylan Sands on 3/12/20.
//

import UIKit

class RecordButtonView: UIView {

    enum RecordingState {
        case ready
        case recording
    }
    
    let innerCircleView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 30
        view.backgroundColor = RevoColor.recordingRed
        return view
    }()
    
    var activitySpinner = UIActivityIndicatorView(style: .medium)
    
    var currentState: RecordingState = .ready
    
    var recordingMode: RecordingMode = .video {
        didSet {
            switch recordingMode {
            case .video:
                innerCircleView.backgroundColor = RevoColor.recordingRed
                activitySpinner.color = .white
            case .live:
                innerCircleView.backgroundColor = .white
                activitySpinner.color = .black
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.borderColor = UIColor.white.cgColor
        self.isUserInteractionEnabled = true
        self.layer.cornerRadius = 37.5
        self.layer.borderWidth = 4
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        self.addSubview(innerCircleView)
        innerCircleView.translatesAutoresizingMaskIntoConstraints = false
        innerCircleView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        innerCircleView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        innerCircleView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        innerCircleView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        
        self.addSubview(activitySpinner)
        activitySpinner.translatesAutoresizingMaskIntoConstraints = false
        activitySpinner.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        activitySpinner.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        activitySpinner.transform = CGAffineTransform.init(scaleX: 1.2, y: 1.2)
        activitySpinner.stopAnimating()
        activitySpinner.isHidden = true
        activitySpinner.color = .white
    }
    
    func showActivitySpinner() {
        activitySpinner.isHidden = false
        activitySpinner.startAnimating()
    }
    
    func hideActivitySpinner() {
        activitySpinner.isHidden = true
        activitySpinner.stopAnimating()
    }
    
    func animateRecordingButton() {
       
        var newRadius: CGFloat
        var scale: CGFloat
        
        switch currentState {
        case .ready:
            newRadius = 10
            scale = 0.6
            currentState = .recording
        case .recording:
            newRadius = 30
            currentState = .ready
            scale = 1
        }
                
        UIView.animate(withDuration: 0.5) {
            self.innerCircleView.layer.cornerRadius = newRadius
            self.innerCircleView.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
        
    }

}
