//
//  SplitModeStyleView.swift
//  revo
//
//  Created by Waylan Sands on 7/1/21.
//


import UIKit


protocol SplitModeStyleDelegate: class {
    func updateStyleWith(lineHeight: CGFloat, color:  UIColor)
}

/// A view which allows the user to style the SplitBarView when in splitScreen mode
class SplitModeStyleView: UIView {
    
    private var currentColor: UIColor = .black
    private var selectedColor: UIColor = .black
    
    private var currentLineHeight: CGFloat = 4.0
    private var selectedLineHeight: CGFloat = 4.0
    
    private var currentLineHeightButton: UIButton!
    private var selectedLineHeightButton: UIButton!
    
    private var currentColorButton: UIButton!
    private var selectedColorButton: UIButton!
    
    private var lineHeightButtons = [UIButton]()
    private var colorButtons = [UIButton]()
    
    weak var styleDelegate: SplitModeStyleDelegate?
    
    private let lineHeightLabel: UILabel = {
        let label = UILabel()
        label.text = "Line Height"
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    private let backgroundColorLabel: UILabel = {
        let label = UILabel()
        label.text = "Line Color"
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
        button.setTitle("Save", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(saveButtonPress), for: .touchUpInside)
        button.backgroundColor = .black
        button.layer.cornerRadius = 6
        return button
    }()
    
    private let lineHeightStackView: UIStackView = {
        let view = UIStackView()
        view.distribution = .equalSpacing
        return view
    }()
    
    private let mainBackgroundColorStackView: UIStackView = {
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
        optionsPanelView.heightAnchor.constraint(equalToConstant: 390).isActive = true
        optionsPanelView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        optionsPanelView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20).isActive = true
        optionsPanelView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20).isActive = true
        
        self.addSubview(lineHeightLabel)
        lineHeightLabel.translatesAutoresizingMaskIntoConstraints = false
        lineHeightLabel.topAnchor.constraint(equalTo: optionsPanelView.topAnchor, constant: 30).isActive = true
        lineHeightLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        
        self.addSubview(lineHeightStackView)
        lineHeightStackView.translatesAutoresizingMaskIntoConstraints = false
        lineHeightStackView.heightAnchor.constraint(equalToConstant: 38).isActive = true
        lineHeightStackView.topAnchor.constraint(equalTo: lineHeightLabel.bottomAnchor, constant: 15).isActive = true
        lineHeightStackView.leadingAnchor.constraint(equalTo: optionsPanelView.leadingAnchor, constant: 20).isActive = true
        lineHeightStackView.trailingAnchor.constraint(equalTo: optionsPanelView.trailingAnchor, constant: -20).isActive = true
        addHeightButtons()
        
        self.addSubview(backgroundColorLabel)
        backgroundColorLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundColorLabel.topAnchor.constraint(equalTo: lineHeightStackView.bottomAnchor, constant: 30).isActive = true
        backgroundColorLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        
        
        self.addSubview(mainBackgroundColorStackView)
        mainBackgroundColorStackView.translatesAutoresizingMaskIntoConstraints = false
        mainBackgroundColorStackView.topAnchor.constraint(equalTo: backgroundColorLabel.bottomAnchor, constant: 15).isActive = true
        mainBackgroundColorStackView.leadingAnchor.constraint(equalTo: optionsPanelView.leadingAnchor, constant: 20).isActive = true
        mainBackgroundColorStackView.trailingAnchor.constraint(equalTo: optionsPanelView.trailingAnchor, constant: -20).isActive = true
        addColorButtons()
        
        self.addSubview(saveButton)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.heightAnchor.constraint(equalToConstant: 38).isActive = true
        saveButton.bottomAnchor.constraint(equalTo: optionsPanelView.bottomAnchor, constant: -15).isActive = true
        saveButton.leadingAnchor.constraint(equalTo: optionsPanelView.leadingAnchor, constant: 20).isActive = true
        saveButton.trailingAnchor.constraint(equalTo: optionsPanelView.trailingAnchor, constant: -20).isActive = true
    }
    
    private func addHeightButtons() {
        var buttonIndex = 0
        for _ in 0...4 {
            let button = lineHeightButton()
            button.setTitle("\(buttonIndex * 2)pt", for: .normal)
            lineHeightStackView.addArrangedSubview(button)
            lineHeightButtons.append(button)
            
            if buttonIndex * 2 == 4 { // This is the default selection
                button.setTitleColor(.white, for: .normal)
                currentLineHeightButton = button
                button.backgroundColor = .black
            }
            buttonIndex += 1
        }
    }
    
    @objc private func heightSelection(sender: UIButton) {
        selectedLineHeightButton = sender
        updateHeightFrom(button: sender)
        updateSelectedLineHeightButtonStyle()
    }
    
    private func updateSelectedLineHeightButtonStyle() {
        for eachButton in lineHeightStackView.arrangedSubviews as! [UIButton] {
            if eachButton != selectedLineHeightButton {
                eachButton.backgroundColor = UIColor.fromHex(code: "#EEEEEE")
                eachButton.setTitleColor(UIColor.fromHex(code: "#303030"), for: .normal)
            } else {
                eachButton.setTitleColor(.white, for: .normal)
                eachButton.backgroundColor = .black
            }
        }
    }
    
    private func lineHeightButton() -> UIButton {
        let button = UIButton()
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(heightSelection), for: .touchUpInside)
        button.setTitleColor(UIColor.fromHex(code: "#303030"), for: .normal)
        button.backgroundColor = UIColor.fromHex(code: "#EEEEEE")
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 39).isActive = true
        button.heightAnchor.constraint(equalToConstant: 38).isActive = true
        button.layer.cornerRadius = 6
        return button
    }
    
    private func addColorButtons() {
        for eachSet in RevoColor.colorOptions {
            let stackView = verticalStackView()
            for eachColor in eachSet {
                let button = backgroundColorButtonWith(color: eachColor)
                stackView.addArrangedSubview(button)
                colorButtons.append(button)
            }
            mainBackgroundColorStackView.addArrangedSubview(stackView)
        }
    }
    
    private func backgroundColorButtonWith(color: UIColor) -> UIButton {
        let button = UIButton()
        button.addTarget(self, action: #selector(colorSelection), for: .touchUpInside)
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
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.2
            button.layer.shadowOffset = .zero
            button.layer.shadowRadius = 5
        } else if button.backgroundColor == .black{
            currentColorButton = button
            button.layer.borderWidth = 2
        }
    }
    
    @objc private func colorSelection(sender: UIButton) {
        selectedColor = sender.backgroundColor!
        selectedColorButton = sender
        updateColorSelectionStyle()
    }
    
    private func updateColorSelectionStyle() {
        for eachButton in colorButtons {
            if eachButton != selectedColorButton {
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
    
    private func updateHeightFrom(button: UIButton) {
        switch button.titleLabel?.text {
        case "0pt":
            selectedLineHeight = 0
        case "2pt":
            selectedLineHeight = 2
        case "4pt":
            selectedLineHeight = 4
        case "6pt":
            selectedLineHeight = 6
        case "8pt":
            selectedLineHeight = 8
        default:
            break
        }
        
    }
    
    private func resetSelection() {
        self.updateSelectedLineHeightButtonStyle()
        self.updateColorSelectionStyle()
    }
    
    @objc private func saveButtonPress() {
        self.styleDelegate?.updateStyleWith(lineHeight: selectedLineHeight, color: selectedColor)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "savedStyle"), object: nil)
        currentLineHeightButton = selectedLineHeightButton
        currentColorButton = selectedColorButton
        currentLineHeight = selectedLineHeight
        currentColor = selectedColor
        self.removeFromSuperview()
    }
    
    func cancelButtonPress() {
        selectedLineHeightButton = currentLineHeightButton
        selectedColorButton = currentColorButton
        selectedLineHeight = currentLineHeight
        selectedColor = currentColor
        self.removeFromSuperview()
        resetSelection()
    }
    
    
}
