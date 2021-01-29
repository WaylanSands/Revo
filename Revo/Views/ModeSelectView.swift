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
    
    lazy private var modeLabels = [switchLabel, pipLabel, splitLabel, webLabel]
    lazy private var activeLabel: UILabel = switchLabel

    private var labelFont: UIFont = UIFont.systemFont(ofSize: 15, weight: .regular)
    private let screenCenterX = UIScreen.main.bounds.width / 2
    private var stackViewWidth: CGFloat = 0.0
    private var selectionIndex: Int = 0
    
    weak var delegate: ModeSelectionDelegate?
        
    private var initialOffset: CGFloat {
        let label = modeLabels[0]
        return label.text!.widthWith(font: labelFont) / 2
    }
        
    private let switchLabel: UILabel = {
       let label = UILabel()
        label.text = "SWITCH"
        label.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        label.isUserInteractionEnabled = true
        label.textColor = .white
        return label
    }()
    
    private lazy var  pipLabel: UILabel = {
       let label = UILabel()
        label.text = "PIP"
        label.font = labelFont
        label.textColor  = UIColor.white.withAlphaComponent(0.4)
        label.isUserInteractionEnabled = true
        return label
    }()
    
    private lazy var  splitLabel: UILabel = {
       let label = UILabel()
        label.text = "SPLIT"
        label.font = labelFont
        label.textColor = UIColor.white.withAlphaComponent(0.4)
        label.isUserInteractionEnabled = true
        return label
    }()
    
    private lazy var  webLabel: UILabel = {
       let label = UILabel()
        label.text = "WEB"
        label.font = labelFont
        label.textColor = UIColor.white.withAlphaComponent(0.4)
        label.isUserInteractionEnabled = true
        return label
    }()
        
    private let stackView: UIStackView = {
       let view = UIStackView()
        view.distribution = .equalSpacing
        view.spacing = 25
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
            modeLabels.removeAll(where: { $0.text == "PIP" || $0.text == "SPLIT" })
        }
    }
    
    private func configureGestures() {
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(leftSwipe))
        leftSwipeGesture.direction = .left
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(rightSwipe))
        rightSwipeGesture.direction = .right
        
        self.addGestureRecognizer(leftSwipeGesture)
        self.addGestureRecognizer(rightSwipeGesture)
        
        let switchGesture = UITapGestureRecognizer(target: self, action: #selector(switchLabelTapped))
        let splitGesture = UITapGestureRecognizer(target: self, action: #selector(splitLabelTapped))
        let pipGesture = UITapGestureRecognizer(target: self, action: #selector(pipLabelTapped))
        let webGesture = UITapGestureRecognizer(target: self, action: #selector(webLabelTapped))
        
        switchLabel.addGestureRecognizer(switchGesture)
        splitLabel.addGestureRecognizer(splitGesture)
        pipLabel.addGestureRecognizer(pipGesture)
        webLabel.addGestureRecognizer(webGesture)
    }
    
    private func findTotalWith() {
        for each in modeLabels {
            stackViewWidth += each.text!.widthWith(font: each.font)
            stackViewWidth += stackView.spacing
        }
        stackViewWidth -= stackView.spacing
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func configureViews() {
        self.addSubview(stackView)
        stackView.frame = CGRect(x: screenCenterX - initialOffset, y: 0, width: stackViewWidth, height: 50)
        
        if AVCaptureMultiCamSession.isMultiCamSupported {
            stackView.addArrangedSubview(switchLabel)
            stackView.addArrangedSubview(pipLabel)
            stackView.addArrangedSubview(splitLabel)
            stackView.addArrangedSubview(webLabel)
        } else {
            stackView.addArrangedSubview(switchLabel)
            stackView.addArrangedSubview(webLabel)
        }
    }
    
    private func offsetForLabel(index: Int) {
        var offSet: CGFloat = 0
        
        for each in modeLabels.prefix(through: index) {
            offSet += each.frame.width
            offSet += stackView.spacing
            if each == modeLabels[index] {
                offSet -= each.frame.width / 2
                offSet -= stackView.spacing
                activeLabel = each
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
        default:
            break
        }
    }
    
    private func animateModeLabelsTo(x: CGFloat) {
        updateSelectedStyle()
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.stackView.frame = CGRect(x: x, y: 0, width: self.stackViewWidth, height: 50)
        }) { _ in
            self.updatePresentationTo(mode: self.activeLabel.text!)
        }
    }
    
    private func updateSelectedStyle() {
        for each in modeLabels {
            if each != activeLabel {
                each.textColor = UIColor.white.withAlphaComponent(0.4)
                each.font = labelFont
            } else {
                each.textColor = .white
                each.font = UIFont.systemFont(ofSize: 15, weight: .bold)
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
        case "WEB":
            updatePresentationTo(mode: .web)
        default:
            break
        }
    }
    
    private func updatePresentationTo(mode: PresentationMode) {
        delegate?.changeModeTo(mode)
    }
    
    @objc func switchLabelTapped() {
        let index = modeLabels.firstIndex(of: switchLabel)!
        selectionIndex = index
        offsetForLabel(index: index)
        updateSelectedStyle()
    }
    
    @objc private func pipLabelTapped() {
        let index = modeLabels.firstIndex(of: pipLabel)!
        selectionIndex = index
        offsetForLabel(index: index)
        updateSelectedStyle()
    }
    
    @objc func splitLabelTapped() {
        let index = modeLabels.firstIndex(of: splitLabel)!
        selectionIndex = index
        offsetForLabel(index: index)
        updateSelectedStyle()
    }
    
    @objc private func webLabelTapped() {
        let index = modeLabels.firstIndex(of: webLabel)!
        selectionIndex = index
        offsetForLabel(index: index)
        updateSelectedStyle()
    }

}
