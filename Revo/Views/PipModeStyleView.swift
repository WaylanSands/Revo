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
    
    var currentFrameStyle: FrameStyle = .square
    var selectedFrameStyle: FrameStyle = .square
    
    var currentColor: UIColor = .white
    var selectedColor: UIColor = .white
    
    var currentBoarderWidth: CGFloat = 4.0
    var selectedBoarderWidth: CGFloat = 4.0
    
    var currentBoarderWidthButton: UIButton!
    var selectedBoarderWidthButton: UIButton!
    
    var currentBoarderColorButton: UIButton!
    var selectedBoarderColorButton: UIButton!
    
    var boarderWidthButtons = [UIButton]()
    var boarderColorButtons = [UIButton]()
    
    weak var styleDelegate: PipModeStyleDelegate?
    
    let frameStyleLabel: UILabel = {
        let label = UILabel()
        label.text = "Frame Style"
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    let frameStyleControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Square", "Circle"])
        control.addTarget(self, action: #selector(frameStyleChanged), for: .valueChanged)
        control.selectedSegmentIndex = 0
        return control
    }()
    
    let boarderWidthLabel: UILabel = {
        let label = UILabel()
        label.text = "Boarder Width"
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    
    let boarderColorLabel: UILabel = {
        let label = UILabel()
        label.text = "Boarder Color"
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    
    let optionsPanelView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 15
        return view
    }()
    
    let saveButton: UIButton = {
        let button = UIButton()
        button.setTitle("Save", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(saveButtonPress), for: .touchUpInside)
        button.backgroundColor = .black
        button.layer.cornerRadius = 6
        return button
    }()
    
    let boarderWidthStackView: UIStackView = {
        let view = UIStackView()
        view.distribution = .equalSpacing
        return view
    }()
    
    let mainStrokeColorStackView: UIStackView = {
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
    
    deinit {
        print("Gone")
    }
    
    func configureViews() {
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
        
        self.addSubview(boarderWidthLabel)
        boarderWidthLabel.translatesAutoresizingMaskIntoConstraints = false
        boarderWidthLabel.topAnchor.constraint(equalTo: frameStyleControl.bottomAnchor, constant: 30).isActive = true
        boarderWidthLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        
        self.addSubview(boarderWidthStackView)
        boarderWidthStackView.translatesAutoresizingMaskIntoConstraints = false
        boarderWidthStackView.heightAnchor.constraint(equalToConstant: 38).isActive = true
        boarderWidthStackView.topAnchor.constraint(equalTo: boarderWidthLabel.bottomAnchor, constant: 15).isActive = true
        boarderWidthStackView.leadingAnchor.constraint(equalTo: optionsPanelView.leadingAnchor, constant: 20).isActive = true
        boarderWidthStackView.trailingAnchor.constraint(equalTo: optionsPanelView.trailingAnchor, constant: -20).isActive = true
        addStrokeButtons()
        
        self.addSubview(boarderColorLabel)
        boarderColorLabel.translatesAutoresizingMaskIntoConstraints = false
        boarderColorLabel.topAnchor.constraint(equalTo: boarderWidthStackView.bottomAnchor, constant: 30).isActive = true
        boarderColorLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        
        
        self.addSubview(mainStrokeColorStackView)
        mainStrokeColorStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStrokeColorStackView.topAnchor.constraint(equalTo: boarderColorLabel.bottomAnchor, constant: 15).isActive = true
        mainStrokeColorStackView.leadingAnchor.constraint(equalTo: optionsPanelView.leadingAnchor, constant: 20).isActive = true
        mainStrokeColorStackView.trailingAnchor.constraint(equalTo: optionsPanelView.trailingAnchor, constant: -20).isActive = true
        addBoarderColorButtons()
        
        self.addSubview(saveButton)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.heightAnchor.constraint(equalToConstant: 38).isActive = true
        saveButton.bottomAnchor.constraint(equalTo: optionsPanelView.bottomAnchor, constant: -15).isActive = true
        saveButton.leadingAnchor.constraint(equalTo: optionsPanelView.leadingAnchor, constant: 20).isActive = true
        saveButton.trailingAnchor.constraint(equalTo: optionsPanelView.trailingAnchor, constant: -20).isActive = true
    }
    
    func addStrokeButtons() {
        var buttonIndex = 0
        for _ in 0...4 {
            let button = strokeWidthButton()
            button.setTitle("\(buttonIndex * 2)pt", for: .normal)
            boarderWidthStackView.addArrangedSubview(button)
            boarderWidthButtons.append(button)
            
            if buttonIndex * 2 == 4 { // This is the default selection
                button.setTitleColor(.white, for: .normal)
                currentBoarderWidthButton = button
                button.backgroundColor = .black
            }
            buttonIndex += 1
        }
    }
    
    @objc func boarderSelection(sender: UIButton) {
        selectedBoarderWidthButton = sender
        updateWidthFrom(button: sender)
        updateSelectedBoarderWidthButtonStyle()
    }
    
    func updateSelectedBoarderWidthButtonStyle() {
        for eachButton in boarderWidthStackView.arrangedSubviews as! [UIButton] {
            if eachButton != selectedBoarderWidthButton {
                eachButton.backgroundColor = UIColor.fromHex(code: "#EEEEEE")
                eachButton.setTitleColor(UIColor.fromHex(code: "#303030"), for: .normal)
            } else {
                eachButton.setTitleColor(.white, for: .normal)
                eachButton.backgroundColor = .black
            }
        }
    }
    
    func strokeWidthButton() -> UIButton {
        let button = UIButton()
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(boarderSelection), for: .touchUpInside)
        button.setTitleColor(UIColor.fromHex(code: "#303030"), for: .normal)
        button.backgroundColor = UIColor.fromHex(code: "#EEEEEE")
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 39).isActive = true
        button.heightAnchor.constraint(equalToConstant: 38).isActive = true
        button.layer.cornerRadius = 6
        return button
    }
    
    func addBoarderColorButtons() {
        for eachSet in RevoColor.colorOptions {
            let stackView = verticalStackView()
            for eachColor in eachSet {
                let button = boarderColorButtonWith(color: eachColor)
                stackView.addArrangedSubview(button)
                boarderColorButtons.append(button)
            }
            mainStrokeColorStackView.addArrangedSubview(stackView)
        }
    }
    
    func boarderColorButtonWith(color: UIColor) -> UIButton {
        let button = UIButton()
        button.addTarget(self, action: #selector(boarderColorSelection), for: .touchUpInside)
        button.layer.borderColor = RevoColor.colorButtonSelectionColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 37).isActive = true
        button.heightAnchor.constraint(equalToConstant: 37).isActive = true
        button.layer.cornerRadius = 18.5
        button.backgroundColor = color
        addStyleIfWhite(button: button)
        return button
    }
    
    func addStyleIfWhite(button: UIButton) {
        if button.backgroundColor == .white {
            currentBoarderColorButton = button
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.2
            button.layer.shadowOffset = .zero
            button.layer.shadowRadius = 5
            button.layer.borderWidth = 2
        }
    }
    
    @objc func boarderColorSelection(sender: UIButton) {
        selectedColor = sender.backgroundColor!
        selectedBoarderColorButton = sender
        updateBoarderColorSelectionStyle()
    }
    
    func updateBoarderColorSelectionStyle() {
        for eachButton in boarderColorButtons {
            if eachButton != selectedBoarderColorButton {
                eachButton.layer.borderWidth = 0
            } else {
                eachButton.layer.borderWidth = 2
            }
        }
    }
    
    func verticalStackView() -> UIStackView {
        let view = UIStackView()
        view.distribution = .equalSpacing
        view.axis = .vertical
        view.spacing = 15
        return view
    }
    
    @objc func frameStyleChanged(control: UISegmentedControl) {
        let selectedIndex = control.selectedSegmentIndex
        let selectedSegment = control.titleForSegment(at: selectedIndex)
        switch selectedSegment {
        case "Circle" :
            print("Circle")
            selectedFrameStyle = .circular
        case "Square":
            print("Square")
            selectedFrameStyle = .square
        default:
            break
        }
        
    }
    
    
    func updateWidthFrom(button: UIButton) {
        switch button.titleLabel?.text {
        case "0pt":
            selectedBoarderWidth = 0
        case "2pt":
            selectedBoarderWidth = 2
        case "4pt":
            selectedBoarderWidth = 4
        case "6pt":
            selectedBoarderWidth = 6
        case "8pt":
            selectedBoarderWidth = 8
        default:
            break
        }
        
    }
    
    func resetFrameControl() {
        switch selectedFrameStyle {
        case .square:
            frameStyleControl.selectedSegmentIndex = 0
        case .circular:
            frameStyleControl.selectedSegmentIndex = 1
        }
    }
    
    func resetSelection() {
        self.updateSelectedBoarderWidthButtonStyle()
        self.updateBoarderColorSelectionStyle()
        self.resetFrameControl()
    }
    
    @objc func saveButtonPress() {
        self.styleDelegate?.updateStyleWith(style: selectedFrameStyle, borderWidth: selectedBoarderWidth, color: selectedColor)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "savedStyle"), object: nil)
        currentBoarderWidthButton = selectedBoarderWidthButton
        currentBoarderColorButton = selectedBoarderColorButton
        currentBoarderWidth = selectedBoarderWidth
        currentColor = selectedColor
        currentFrameStyle = selectedFrameStyle
        self.removeFromSuperview()
    }
    
    func cancelButtonPress() {
        selectedBoarderWidthButton = currentBoarderWidthButton
        selectedBoarderColorButton = currentBoarderColorButton
        selectedBoarderWidth = currentBoarderWidth
        selectedColor = currentColor
        selectedFrameStyle = currentFrameStyle
        self.removeFromSuperview()
        resetSelection()
    }
    
    
}
