//
//  FocusAnimationView.swift
//  Revo
//
//  Created by Waylan Sands on 10/12/20.
//

import Lottie
import UIKit

class FocusAnimationView: UIView {
    
    var animationView: AnimationView!
    let startFrame = AnimationFrameTime(50)
    let endFrame = AnimationFrameTime(130)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configureView() {
        animationView = AnimationView(name: "focus_animation")
        animationView.loopMode = .playOnce

        self.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.widthAnchor.constraint(equalToConstant: 190).isActive = true
        animationView.heightAnchor.constraint(equalToConstant: 190).isActive = true
        animationView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        animationView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    }
    
    func playAnimation() {
        animationView.play(fromFrame: startFrame, toFrame: endFrame, loopMode: .playOnce, completion: { [self] _ in
            self.removeFromSuperview()
        })
    }
    
    func showFocusFrame() {
        self.alpha = 0
        UIView.animate(withDuration: 1, delay: 0, options: .curveEaseIn) {
            self.alpha = 1
        } completion: { _ in
            self.removeFromSuperview()
        }
    }
    
    func stopAnimation() {
        animationView.stop()
    }
    
}
