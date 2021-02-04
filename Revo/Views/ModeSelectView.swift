//
//  ScrollModeView.swift
//  Revo
//
//  Created by Waylan Sands on 27/1/21.
//

import UIKit
import AVFoundation

protocol ModeSelectionDelegate: class {
    func changeModeTo(_ mode: PresentationMode)
}

/// ModeSelectView works like a custom UISegmentControl which allows
/// users to select each Camera Mode more efficiently.
///
/// It mimics the design and functionality used in native Camera app as in iOS 14. Users may
/// swipe left or right to make a selection or tap an individual label.
///
/// The ModeSelectView is also dynamic as it adjusts when device in not MultiCam supported.
class ModeSelectView: UIView {
    
    lazy private var modeButtons: [UIButton] = [switchButton, pipButton, splitButton, uploadButton, webButton]
    lazy private var activeButton: UIButton = switchButton

    private var buttonFont: UIFont = UIFont.systemFont(ofSize: 13.5, weight: .medium)
    private var selectedButtonFont: UIFont = UIFont.systemFont(ofSize: 13.5, weight: .bold)
    private let screenCenterX = UIScreen.main.bounds.width / 2
    private var stackViewWidth: CGFloat = 0.0
    private var selectionIndex: Int = 0
    
    weak var delegate: ModeSelectionDelegate?
        
    private var initialOffset: CGFloat {
        let label = modeButtons[0]
        return (label.titleLabel!.text!.widthWith(font: buttonFont) / 2) + 15
    }
        
    private lazy var switchButton: UIButton = {
       let button = UIButton()
        button.setTitle("SWITCH", for: UIControl.State.normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        button.addTarget(self, action: #selector(switchButtonTapped), for: .touchUpInside)
        button.titleLabel?.font = selectedButtonFont
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 15
        return button
    }()
    
    private lazy var  pipButton: UIButton = {
       let button = UIButton()
        button.setTitle("PIP", for: UIControl.State.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        button.addTarget(self, action: #selector(pipButtonTapped), for: .touchUpInside)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.9), for: .normal)
        button.layer.cornerRadius = 15
        return button
    }()
    
    private lazy var splitButton: UIButton = {
       let button = UIButton()
        button.setTitle("SPLIT", for: UIControl.State.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        button.addTarget(self, action: #selector(splitButtonTapped), for: .touchUpInside)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.9), for: .normal)
        button.layer.cornerRadius = 15
        return button
    }()
    
    private lazy var uploadButton: UIButton = {
       let button = UIButton()
        button.setTitle("UPLOAD", for: UIControl.State.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        button.addTarget(self, action: #selector(uploadButtonTapped), for: .touchUpInside)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.9), for: .normal)
        button.layer.cornerRadius = 15
        return button
    }()
    
    private lazy var webButton: UIButton = {
       let button = UIButton()
        button.setTitle("WEB", for: UIControl.State.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        button.addTarget(self, action: #selector(webButtonTapped), for: .touchUpInside)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.9), for: .normal)
        button.layer.cornerRadius = 15
        return button
    }()
        
    private let stackView: UIStackView = {
       let view = UIStackView()
        view.distribution = .equalSpacing
        view.spacing = 5
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        configureMultiCamSupport()
        configureGestures()
        findTotalWith()
        configureViews()
    }
    
    private func configureMultiCamSupport() {
        if !AVCaptureMultiCamSession.isMultiCamSupported {
            modeButtons.removeAll(where: { $0.titleLabel!.text == "PIP" || $0.titleLabel!.text == "SPLIT" })
        }
    }
    
    private func configureGestures() {
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(leftSwipe))
        leftSwipeGesture.direction = .left
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(rightSwipe))
        rightSwipeGesture.direction = .right
        
        self.addGestureRecognizer(leftSwipeGesture)
        self.addGestureRecognizer(rightSwipeGesture)
    }
    
    private func findTotalWith() {
        for each in modeButtons {
            stackViewWidth += each.titleLabel!.text!.widthWith(font: each.titleLabel!.font)
            stackViewWidth += stackView.spacing
            stackViewWidth += 30
        }
        stackViewWidth -= stackView.spacing
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func configureViews() {
        self.addSubview(stackView)
        stackView.frame = CGRect(x: screenCenterX - initialOffset, y: 0, width: stackViewWidth, height: 30)
        
        if AVCaptureMultiCamSession.isMultiCamSupported {
            stackView.addArrangedSubview(switchButton)
            stackView.addArrangedSubview(pipButton)
            stackView.addArrangedSubview(splitButton)
            stackView.addArrangedSubview(uploadButton)
            stackView.addArrangedSubview(webButton)
        } else {
            stackView.addArrangedSubview(switchButton)
            stackView.addArrangedSubview(uploadButton)
            stackView.addArrangedSubview(webButton)
        }
    }
    
    private func offsetForLabel(index: Int) {
        var offSet: CGFloat = 0
        
        for each in modeButtons.prefix(through: index) {
            offSet += each.frame.width
            offSet += stackView.spacing
            if each == modeButtons[index] {
                offSet -= each.frame.width / 2
                offSet -= stackView.spacing
                activeButton = each
            }
        }
        animateModeLabelsTo(x: screenCenterX - offSet)
    }

    @objc private func leftSwipe() {
        switch selectionIndex {
        case 0:
            selectionIndex = 1
            offsetForLabel(index: 1)
        case 1:
            selectionIndex = 2
            offsetForLabel(index: 2)
        case 2:
            selectionIndex = 3
            offsetForLabel(index: 3)
        case 3:
            selectionIndex = 4
            offsetForLabel(index: 4)
        case 4:
            break
        default:
            break
        }
    }
    
    @objc private func rightSwipe() {
        switch selectionIndex {
        case 0:
            break
        case 1:
            selectionIndex = 0
            offsetForLabel(index: 0)
        case 2:
            selectionIndex = 1
            offsetForLabel(index:1)
        case 3:
            selectionIndex = 2
            offsetForLabel(index: 2)
        case 4:
            selectionIndex = 3
            offsetForLabel(index: 3)
        default:
            break
        }
    }
    
    private func animateModeLabelsTo(x: CGFloat) {
        updateSelectedStyle()
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.stackView.frame = CGRect(x: x, y: 0, width: self.stackViewWidth, height: 30)
        }) { _ in
            self.updatePresentationTo(mode: self.activeButton.titleLabel!.text!)
        }
    }
    
    private func updateSelectedStyle() {
        for each in modeButtons {
            if each != activeButton {
                each.setTitleColor(UIColor.white.withAlphaComponent(0.9), for: .normal)
                each.titleLabel!.font = buttonFont
                each.backgroundColor = .clear
            } else {
                each.backgroundColor = UIColor.black.withAlphaComponent(0.4)
                each.titleLabel!.font = selectedButtonFont
                each.setTitleColor(.white, for: .normal)
            }
        }
    }
    
    private func updatePresentationTo(mode: String) {
        switch mode {
        case "SWITCH":
            updatePresentationTo(mode: .switchCam)
        case "PIP":
            updatePresentationTo(mode: .pip)
        case "SPLIT":
            updatePresentationTo(mode: .splitScreen)
        case "UPLOAD":
            updatePresentationTo(mode: .upload)
        case "WEB":
            updatePresentationTo(mode: .web)
        default:
            break
        }
    }
    
    private func updatePresentationTo(mode: PresentationMode) {
        delegate?.changeModeTo(mode)
    }
    
    @objc func switchButtonTapped() {
        let index = modeButtons.firstIndex(of: switchButton)!
        selectionIndex = index
        offsetForLabel(index: index)
        updateSelectedStyle()
    }
    
    @objc private func pipButtonTapped() {
        let index = modeButtons.firstIndex(of: pipButton)!
        selectionIndex = index
        offsetForLabel(index: index)
        updateSelectedStyle()
    }
    
    @objc func splitButtonTapped() {
        let index = modeButtons.firstIndex(of: splitButton)!
        selectionIndex = index
        offsetForLabel(index: index)
        updateSelectedStyle()
    }
    
    @objc func uploadButtonTapped() {
        let index = modeButtons.firstIndex(of: uploadButton)!
        selectionIndex = index
        offsetForLabel(index: index)
        updateSelectedStyle()
    }
    
    @objc private func webButtonTapped() {
        let index = modeButtons.firstIndex(of: webButton)!
        selectionIndex = index
        offsetForLabel(index: index)
        updateSelectedStyle()
    }

}
