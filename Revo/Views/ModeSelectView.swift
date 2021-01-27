//
//  ScrollModeView.swift
//  Revo
//
//  Created by Waylan Sands on 27/1/21.
//

import UIKit

protocol ModeSelectionDelegate {
    func changeModeTo(_ mode: PresentationMode)
}

class ModeSelectView: UIView {
    
    lazy var modeLabels = [switchLabel, pipLabel, splitLabel, webLabel]
    lazy var activeLabel: UILabel = switchLabel

    var labelFont: UIFont = UIFont.systemFont(ofSize: 15, weight: .regular)
    let screenCenterX = UIScreen.main.bounds.width / 2
    var stackViewWidth: CGFloat = 0.0
    var selectionIndex: Int = 0
    
    var modeSelection: ((PresentationMode) -> ())?
    
    var initialOffset: CGFloat {
        let label = modeLabels[0]
        return label.text!.widthWith(font: labelFont) / 2
    }
        
    let switchLabel: UILabel = {
       let label = UILabel()
        label.text = "SWITCH"
        label.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        label.isUserInteractionEnabled = true
        label.textColor = .white
        return label
    }()
    
    lazy var  pipLabel: UILabel = {
       let label = UILabel()
        label.text = "PIP"
        label.font = labelFont
        label.textColor  = UIColor.white.withAlphaComponent(0.4)
        label.isUserInteractionEnabled = true
        return label
    }()
    
    lazy var  splitLabel: UILabel = {
       let label = UILabel()
        label.text = "SPLIT"
        label.font = labelFont
        label.textColor = UIColor.white.withAlphaComponent(0.4)
        label.isUserInteractionEnabled = true
        return label
    }()
    
    lazy var  webLabel: UILabel = {
       let label = UILabel()
        label.text = "WEB"
        label.font = labelFont
        label.textColor = UIColor.white.withAlphaComponent(0.4)
        label.isUserInteractionEnabled = true
        return label
    }()
        
    let stackView: UIStackView = {
       let view = UIStackView()
        view.distribution = .equalSpacing
        view.spacing = 25
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.configureGestures()
        self.findTotalWith()
        self.configureViews()
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
    
    func findTotalWith() {
        for each in modeLabels {
            stackViewWidth += each.text!.widthWith(font: each.font)
            stackViewWidth += stackView.spacing
        }
        stackViewWidth -= stackView.spacing
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configureViews() {
        self.addSubview(stackView)
        stackView.frame = CGRect(x: screenCenterX - initialOffset, y: 0, width: stackViewWidth, height: 50)

        stackView.addArrangedSubview(switchLabel)
        stackView.addArrangedSubview(pipLabel)
        stackView.addArrangedSubview(splitLabel)
        stackView.addArrangedSubview(webLabel)
    }
    
    func offsetForLabel(index: Int) {
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

    @objc func leftSwipe() {
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
    
    @objc func rightSwipe() {
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
    
    func animateModeLabelsTo(x: CGFloat) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.stackView.frame = CGRect(x: x, y: 0, width: self.stackViewWidth, height: 50)
        }) { _ in
            self.updateSelectedStyle()
        }
    }
    
    func updateSelectedStyle() {
        for each in modeLabels {
            if each != activeLabel {
                each.textColor = UIColor.white.withAlphaComponent(0.4)
                each.font = labelFont
            } else {
                each.textColor = .white
                each.font = UIFont.systemFont(ofSize: 15, weight: .bold)
                updatePresentationTo(mode: each.text!)
            }
        }
    }
    
    func updatePresentationTo(mode: String) {
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
    
    func updatePresentationTo(mode: PresentationMode) {
        guard let modeSelection = modeSelection else {
            fatalError("Mode selection closure was nil")
        }
        modeSelection(mode)
    }
    
    @objc func switchLabelTapped() {
        selectionIndex = 0
        offsetForLabel(index: 0)
    }
    
    @objc func pipLabelTapped() {
        selectionIndex = 1
        offsetForLabel(index: 1)
    }
    
    @objc func splitLabelTapped() {
        selectionIndex = 2
        offsetForLabel(index: 2)
    }
    
    @objc func webLabelTapped() {
        selectionIndex = 3
        offsetForLabel(index:3)
    }

}
