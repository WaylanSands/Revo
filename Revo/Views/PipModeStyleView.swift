//
//  FrontFrameEditingView.swift
//  Revo
//
//  Created by Waylan Sands on 3/12/20.
//

import UIKit

protocol PipModeStyleDelegate: class {
    func updateStyleWith(style: FrameStyle, borderWidth: CGFloat, color:  UIColor)
}

/// A view which allows the user to style the look of the floating PreviewView "PIP)
class PipModeStyleView: UIView {
    
    private var currentFrameStyle: FrameStyle = .square
    private var selectedFrameStyle: FrameStyle = .square
    
    private var currentColor: UIColor = .white
    private var selectedColor: UIColor = .white
    
    private var currentBorderWidth: CGFloat = 4.0
    private var selectedBorderWidth: CGFloat = 4.0
    
    private var currentBorderWidthButton: UIButton!
    private var selectedBorderWidthButton: UIButton!
    
    private var currentBorderColorButton: UIButton!
    private var selectedBorderColorButton: UIButton!
    
    private var borderWidthButtons = [UIButton]()
    private var borderColorButtons = [UIButton]()
    
    weak var styleDelegate: PipModeStyleDelegate?
    
    private let frameStyleLabel: UILabel = {
        let label = UILabel()
        label.text = "Frame Style".localized
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    private let frameStyleControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Square".localized, "Circle".localized])
        control.addTarget(self, action: #selector(frameStyleChanged), for: .valueChanged)
        control.selectedSegmentIndex = 0
        return control
    }()
    
    private let borderWidthLabel: UILabel = {
        let label = UILabel()
        label.text = "Border Width".localized
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    
    private let borderColorLabel: UILabel = {
        let label = UILabel()
        label.text = "Border Color".localized
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    
    private let optionsPanelView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 15
        return view
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton()
        button.setTitle("Save".localized, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(saveButtonPress), for: .touchUpInside)
        button.backgroundColor = .black
        button.layer.cornerRadius = 6
        return button
    }()
    
    private let borderWidthStackView: UIStackView = {
        let view = UIStackView()
        view.distribution = .equalSpacing
        return view
    }()
    
    private let mainStrokeColorStackView: UIStackView = {
        let view = UIStackView()
        view.distribution = .equalSpacing
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        self.isUserInteractionEnabled = true
        configureViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func configureViews() {
        self.addSubview(optionsPanelView)
        optionsPanelView.translatesAutoresizingMaskIntoConstraints = false
        optionsPanelView.heightAnchor.constraint(equalToConstant: 490).isActive = true
        optionsPanelView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        optionsPanelView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20).isActive = true
        optionsPanelView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20).isActive = true
        
        self.addSubview(frameStyleLabel)
        frameStyleLabel.translatesAutoresizingMaskIntoConstraints = false
        frameStyleLabel.topAnchor.constraint(equalTo: optionsPanelView.topAnchor, constant: 30).isActive = true
        frameStyleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        
        self.addSubview(frameStyleControl)
        frameStyleControl.translatesAutoresizingMaskIntoConstraints = false
        frameStyleControl.topAnchor.constraint(equalTo: frameStyleLabel.bottomAnchor, constant: 15).isActive = true
        frameStyleControl.leadingAnchor.constraint(equalTo: optionsPanelView.leadingAnchor, constant: 20).isActive = true
        frameStyleControl.trailingAnchor.constraint(equalTo: optionsPanelView.trailingAnchor, constant: -20).isActive = true
        
        self.addSubview(borderWidthLabel)
        borderWidthLabel.translatesAutoresizingMaskIntoConstraints = false
        borderWidthLabel.topAnchor.constraint(equalTo: frameStyleControl.bottomAnchor, constant: 30).isActive = true
        borderWidthLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        
        self.addSubview(borderWidthStackView)
        borderWidthStackView.translatesAutoresizingMaskIntoConstraints = false
        borderWidthStackView.heightAnchor.constraint(equalToConstant: 38).isActive = true
        borderWidthStackView.topAnchor.constraint(equalTo: borderWidthLabel.bottomAnchor, constant: 15).isActive = true
        borderWidthStackView.leadingAnchor.constraint(equalTo: optionsPanelView.leadingAnchor, constant: 20).isActive = true
        borderWidthStackView.trailingAnchor.constraint(equalTo: optionsPanelView.trailingAnchor, constant: -20).isActive = true
        addStrokeButtons()
        
        self.addSubview(borderColorLabel)
        borderColorLabel.translatesAutoresizingMaskIntoConstraints = false
        borderColorLabel.topAnchor.constraint(equalTo: borderWidthStackView.bottomAnchor, constant: 30).isActive = true
        borderColorLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        
        
        self.addSubview(mainStrokeColorStackView)
        mainStrokeColorStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStrokeColorStackView.topAnchor.constraint(equalTo: borderColorLabel.bottomAnchor, constant: 15).isActive = true
        mainStrokeColorStackView.leadingAnchor.constraint(equalTo: optionsPanelView.leadingAnchor, constant: 20).isActive = true
        mainStrokeColorStackView.trailingAnchor.constraint(equalTo: optionsPanelView.trailingAnchor, constant: -20).isActive = true
        addBorderColorButtons()
        
        self.addSubview(saveButton)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.heightAnchor.constraint(equalToConstant: 38).isActive = true
        saveButton.bottomAnchor.constraint(equalTo: optionsPanelView.bottomAnchor, constant: -15).isActive = true
        saveButton.leadingAnchor.constraint(equalTo: optionsPanelView.leadingAnchor, constant: 20).isActive = true
        saveButton.trailingAnchor.constraint(equalTo: optionsPanelView.trailingAnchor, constant: -20).isActive = true
    }
    
    private func addStrokeButtons() {
        var buttonIndex = 0
        for _ in 0...4 {
            let button = strokeWidthButton()
            button.setTitle("\(buttonIndex * 2)pt", for: .normal)
            borderWidthStackView.addArrangedSubview(button)
            borderWidthButtons.append(button)
            
            if buttonIndex * 2 == 4 { // This is the default selection
                button.setTitleColor(.white, for: .normal)
                currentBorderWidthButton = button
                button.backgroundColor = .black
            }
            buttonIndex += 1
        }
    }
    
    @objc private func borderSelection(sender: UIButton) {
        selectedBorderWidthButton = sender
        updateWidthFrom(button: sender)
        updateSelectedBorderWidthButtonStyle()
    }
    
    private func updateSelectedBorderWidthButtonStyle() {
        for eachButton in borderWidthStackView.arrangedSubviews as! [UIButton] {
            if eachButton != selectedBorderWidthButton {
                eachButton.backgroundColor = UIColor.fromHex(code: "#EEEEEE")
                eachButton.setTitleColor(UIColor.fromHex(code: "#303030"), for: .normal)
            } else {
                eachButton.setTitleColor(.white, for: .normal)
                eachButton.backgroundColor = .black
            }
        }
    }
    
    private func strokeWidthButton() -> UIButton {
        let button = UIButton()
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(borderSelection), for: .touchUpInside)
        button.setTitleColor(UIColor.fromHex(code: "#303030"), for: .normal)
        button.backgroundColor = UIColor.fromHex(code: "#EEEEEE")
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 39).isActive = true
        button.heightAnchor.constraint(equalToConstant: 38).isActive = true
        button.layer.cornerRadius = 6
        return button
    }
    
    private func addBorderColorButtons() {
        for eachSet in RevoColor.colorOptions {
            let stackView = verticalStackView()
            for eachColor in eachSet {
                let button = borderColorButtonWith(color: eachColor)
                stackView.addArrangedSubview(button)
                borderColorButtons.append(button)
            }
            mainStrokeColorStackView.addArrangedSubview(stackView)
        }
    }
    
    private func borderColorButtonWith(color: UIColor) -> UIButton {
        let button = UIButton()
        button.addTarget(self, action: #selector(borderColorSelection), for: .touchUpInside)
        button.layer.borderColor = RevoColor.colorButtonSelectionColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 37).isActive = true
        button.heightAnchor.constraint(equalToConstant: 37).isActive = true
        button.layer.cornerRadius = 18.5
        button.backgroundColor = color
        addStyleIfWhite(button: button)
        return button
    }
    
    private func addStyleIfWhite(button: UIButton) {
        if button.backgroundColor == .white {
            currentBorderColorButton = button
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.2
            button.layer.shadowOffset = .zero
            button.layer.shadowRadius = 5
            button.layer.borderWidth = 2
        }
    }
    
    @objc private func borderColorSelection(sender: UIButton) {
        selectedColor = sender.backgroundColor!
        selectedBorderColorButton = sender
        updateBorderColorSelectionStyle()
    }
    
    private func updateBorderColorSelectionStyle() {
        for eachButton in borderColorButtons {
            if eachButton != selectedBorderColorButton {
                eachButton.layer.borderWidth = 0
            } else {
                eachButton.layer.borderWidth = 2
            }
        }
    }
    
    private func verticalStackView() -> UIStackView {
        let view = UIStackView()
        view.distribution = .equalSpacing
        view.axis = .vertical
        view.spacing = 15
        return view
    }
    
    @objc private func frameStyleChanged(control: UISegmentedControl) {
        let selectedIndex = control.selectedSegmentIndex
        let selectedSegment = control.titleForSegment(at: selectedIndex)
        switch selectedSegment {
        case "Circle".localized:
            selectedFrameStyle = .circular
        case "Square".localized:
            selectedFrameStyle = .square
        default:
            break
        }
    }
    
    
    private func updateWidthFrom(button: UIButton) {
        switch button.titleLabel?.text {
        case "0pt":
            selectedBorderWidth = 0
        case "2pt":
            selectedBorderWidth = 2
        case "4pt":
            selectedBorderWidth = 4
        case "6pt":
            selectedBorderWidth = 6
        case "8pt":
            selectedBorderWidth = 8
        default:
            break
        }
        
    }
    
    private func resetFrameControl() {
        switch selectedFrameStyle {
        case .square:
            frameStyleControl.selectedSegmentIndex = 0
        case .circular:
            frameStyleControl.selectedSegmentIndex = 1
        }
    }
    
    private func resetSelection() {
        self.updateSelectedBorderWidthButtonStyle()
        self.updateBorderColorSelectionStyle()
        self.resetFrameControl()
    }
    
    @objc private func saveButtonPress() {
        self.styleDelegate?.updateStyleWith(style: selectedFrameStyle, borderWidth: selectedBorderWidth, color: selectedColor)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "savedStyle"), object: nil)
        currentBorderWidthButton = selectedBorderWidthButton
        currentBorderColorButton = selectedBorderColorButton
        currentBorderWidth = selectedBorderWidth
        currentColor = selectedColor
        currentFrameStyle = selectedFrameStyle
        self.removeFromSuperview()
        
        // Log event to Firebase Analytics
        RevoAnalytics.editedPipStyle()
    }
    
    func cancelButtonPress() {
        selectedBorderWidthButton = currentBorderWidthButton
        selectedBorderColorButton = currentBorderColorButton
        selectedBorderWidth = currentBorderWidth
        selectedColor = currentColor
        selectedFrameStyle = currentFrameStyle
        self.removeFromSuperview()
        resetSelection()
    }
    
    
}
