//
//  LibraryVC.swift
//  Revo
//
//  Created by Waylan Sands on 6/12/20.
//

import UIKit
import AVKit
import Lottie
import AVFoundation

enum SelectionState {
    case inactive
    case active
}

class LibraryVC: UIViewController {
    
    private var recordings = [Recording]()
    private var selectedRecordingsURLs = [URL]()
    
    private var selectionState: SelectionState = .inactive
        
    private lazy var layOut: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        let cellWidth = (view.frame.width / 2) - 21.5
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth * 1.5 )
        layout.sectionInset = UIEdgeInsets(top: 60, left: 14, bottom: 60, right: 14)
        layout.minimumInteritemSpacing = 15
        layout.minimumLineSpacing = 16
        return layout
    }()
    
    private lazy var libraryCollectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layOut)
        view.register(RecordingViewCell.self, forCellWithReuseIdentifier: "RecordingViewCell")
        view.backgroundColor = .white
        return view
    }()
    
    private let downArrowButton: UIButton = {
        let button = UIButton()
        button.setImage(RevoImages.blackDownArrow, for: .normal)
        button.addTarget(self, action: #selector(downArrowPress), for: .touchUpInside)
        return button
    }()
    
    private lazy var gradientLayer: CAGradientLayer = {
        let topColor =  UIColor.black.cgColor
        let bottomColor =  UIColor.black.withAlphaComponent(0).cgColor
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [topColor, bottomColor]
        gradientLayer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 110)
        return gradientLayer
    }()
    
    private lazy var topGradientView: UIView = {
        let gradientView = UIView()
        gradientView.layer.addSublayer(gradientLayer)
        gradientView.alpha = 0.0
        return gradientView
    }()
    
    private let selectButton: UIButton = {
        let button = UIButton()
        button.setTitle("Select", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        button.addUIBlurEffectWith(effect: UIBlurEffect(style: .light), cornerRadius: 15)
        button.addTarget(self, action: #selector(selectPress), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        button.layer.cornerRadius = 15
        return button
    }()
    
    private let appLogoLabel: UILabel = {
        let label = UILabel()
        label.text = "revo"
        label.textColor = RevoColor.blackText
        label.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        return label
    }()
    
    private let recordingOptionsView: RecordingOptionsView = {
        let view = RecordingOptionsView()
        view.shareButton.addTarget(self, action: #selector(shareRecordings), for: .touchUpInside)
        view.deleteButton.addTarget(self, action: #selector(deletePress), for: .touchUpInside)
        return view
    }()
    
    private let animatingCellThumbnail: UIView = {
        let view = UIView()
        return view
    }()
    
    private let emptyCollectionAnimation: AnimationView = {
       let animationView = AnimationView(name: "mobile_360_animation")
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.isHidden = true
        return animationView
    }()
    
    private lazy var emptyCollectionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = RevoColor.blackText
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureDelegates()
        configureSwipeGesture()
        fetchRecordings()
        configureViews()
    }
    
    private func configureSwipeGesture() {
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(downSwipe))
        swipeGesture.direction = .down
        self.view.addGestureRecognizer(swipeGesture)
    }
    
    @objc private func downSwipe() {
        if recordings.count == 0 {
            dismiss(animated: true, completion: nil)
        }
    }
    
    private func fetchRecordings() {
        guard let fileURLs = FileManager.getFileURLsFromDocumentsDirectory() else {
            return
        }

        for eachURL in fileURLs {
            let recording = Recording(fileURL: eachURL)
            recordings.append(recording)
        }
        
        configureIfLibraryIsEmpty()

        DispatchQueue.main.async {
            self.libraryCollectionView.reloadData()
        }
    }
    
    private func configureDelegates() {
        libraryCollectionView.dataSource = self
        libraryCollectionView.delegate = self
    }
    
    private func configureViews() {
        view.backgroundColor = .white
        
        view.addSubview(libraryCollectionView)
        libraryCollectionView.translatesAutoresizingMaskIntoConstraints = false
        libraryCollectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        libraryCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        libraryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        libraryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        
        view.addSubview(topGradientView)
        topGradientView.translatesAutoresizingMaskIntoConstraints = false
        topGradientView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        topGradientView.heightAnchor.constraint(equalToConstant: 110).isActive = true
        topGradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        topGradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        view.addSubview(downArrowButton)
        downArrowButton.translatesAutoresizingMaskIntoConstraints = false
        downArrowButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 60).isActive = true
        downArrowButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        
        view.addSubview(appLogoLabel)
        appLogoLabel.translatesAutoresizingMaskIntoConstraints = false
        appLogoLabel.centerYAnchor.constraint(equalTo: downArrowButton.centerYAnchor).isActive = true
        appLogoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.addSubview(selectButton)
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        selectButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 60).isActive = true
        selectButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        selectButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        view.addSubview(emptyCollectionAnimation)
        emptyCollectionAnimation.translatesAutoresizingMaskIntoConstraints = false
        emptyCollectionAnimation.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100).isActive = true
        emptyCollectionAnimation.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        emptyCollectionAnimation.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        emptyCollectionAnimation.heightAnchor.constraint(equalToConstant: 300).isActive = true
        
        view.addSubview(emptyCollectionLabel)
        emptyCollectionLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyCollectionLabel.topAnchor.constraint(equalTo: emptyCollectionAnimation.bottomAnchor, constant: -30).isActive = true
        emptyCollectionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        emptyCollectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        
        view.addSubview(recordingOptionsView)
        recordingOptionsView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height, width: UIScreen.main.bounds.width, height: 80)

    }
    
    @objc private func downArrowPress() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func selectPress() {
        switch selectionState {
        case .inactive:
            selectionState = .active
            selectButton.setTitle("Cancel", for: .normal)
        case .active:
            selectionState = .inactive
            makeAllCellsInactive()
            selectButton.setTitle("Select", for: .normal)
        }
    }
    
    private func makeAllCellsInactive() {
        self.recordingOptionsView.updatePositionTo(state: selectionState)
        for each in libraryCollectionView.visibleCells as! [RecordingViewCell] {
            each.makeInActive()
        }
    }
    
    // MARK: - Selection Options
    
    @objc private func shareRecordings() {
        let activityVC = UIActivityViewController(activityItems: selectedRecordingsURLs, applicationActivities: nil)
        DispatchQueue.main.async {
            self.present(activityVC, animated: true)
        }
    }
    
    @objc private func saveToCameraRoll() {
        for eachURL in selectedRecordingsURLs {
            UISaveVideoAtPathToSavedPhotosAlbum(eachURL.path, nil, nil, nil)
        }
    }
    
    // Check to see if user really wants to delete recordings
    @objc private func deletePress() {
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
    
    private func deleteRecordings() {
        for eachURL in selectedRecordingsURLs {
            FileManager.removeItemWith(url: eachURL)
            recordings.removeAll(where: {$0.fileURL == eachURL})
        }
        recordingOptionsView.updatePositionTo(state: .inactive)
        selectButton.setTitle("Select", for: .normal)
        selectionState = .inactive
        
        configureIfLibraryIsEmpty()
        
        libraryCollectionView.reloadData()
    }
    
    private func configureIfLibraryIsEmpty() {
        if recordings.isEmpty {
            emptyCollectionAnimation.isHidden = false
            emptyCollectionAnimation.play()
            emptyCollectionLabel.isHidden = false
            updateEmptyCollectionLabelText()
            selectButton.isHidden = true
        } else {
            // Tracking if the user has visited the library with recordings to
            // provide a more intelligent UI
            UserDefaults.standard.setValue(true, forKey: "visitedLibraryWithRecording")
        }
    }
    
    private func updateEmptyCollectionLabelText() {
        if UserDefaults.standard.bool(forKey: "visitedLibraryWithRecording") {
            // This is a returning user
            emptyCollectionLabel.text = "Library currently empty"
        } else {
            emptyCollectionLabel.text = "Recordings will appear here"
        }
    }

}

extension LibraryVC: UICollectionViewDelegate,  UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        recordings.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let recording = recordings[indexPath.item]
        let cell = libraryCollectionView.dequeueReusableCell(withReuseIdentifier: "RecordingViewCell", for: indexPath) as! RecordingViewCell
        cell.setupCellWith(recording: recording)
        cell.recordingCellDelegate = self
        if !selectedRecordingsURLs.contains(recording.fileURL) {
            cell.makeInActive()
        } else {
            cell.makeActive()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! RecordingViewCell
        if selectionState == .active {
            recordingOptionsView.updatePositionTo(state: selectionState)
            cell.selectLibraryCell()
        } else {
            showRecordingWith(url: cell.recording.fileURL)
        }
    }
    
    func showRecordingWith(url: URL) {
        let previewVC = RecordingPreviewVC(recordingURL: url)
        previewVC.deletionDelegate = self
        previewVC.modalPresentationStyle = .fullScreen
        self.present(previewVC, animated: false, completion: nil)
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y

        if offsetY > 20 {
            // Will change the top content to white with dark gradient as background for contrast
            // The status bar colour will animate with the gradient
            downArrowButton.setImage(RevoImages.whiteDownArrow, for: .normal)
            animateGradientAlphaTo(value: 1.0)
            selectButton.backgroundColor = .clear
            selectButton.setTitleColor(.white, for: .normal)
            appLogoLabel.textColor = .white
        } else {
            // Will change the top content to black and remove the gradient
            downArrowButton.setImage(RevoImages.blackDownArrow, for: .normal)
            selectButton.setTitleColor(.black, for: .normal)
            selectButton.backgroundColor = UIColor.black.withAlphaComponent(0.1)
            animateGradientAlphaTo(value: 0.0)
            appLogoLabel.textColor = .black
        }
    }
    
    func animateGradientAlphaTo(value: CGFloat) {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
            self.topGradientView.alpha = value
        }, completion: nil)
    }
    
    // The preferredStatusBarStyle is updated when the user scrolls. The style reflects
    // the text colour of the collection view's title - appLogoLabel
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if appLogoLabel.textColor == .white {
            return .lightContent
        } else {
            return .darkContent
        }
    }
    
}

extension LibraryVC: RecordingViewCellDelegate {
   
    
    func appendSelectedRecordingWith(fileURL: URL) {
        selectedRecordingsURLs.append(fileURL)
        recordingOptionsView.optionsLabel.text = "\(selectedRecordingsURLs.count)  selected"
        recordingOptionsView.optionsLabel.isHidden = false
    }
    
    func removeSelectedRecordingWith(fileURL: URL) {
        selectedRecordingsURLs.removeAll(where: {$0 == fileURL})
        recordingOptionsView.optionsLabel.text = "\(selectedRecordingsURLs.count)  selected"
        
        if selectedRecordingsURLs.isEmpty {
            recordingOptionsView.updatePositionTo(state: .inactive)
        }
    }
    
}

extension LibraryVC: RecordingPreviewDelegate {
    
    func removeRecordingWith(url: URL) {
        FileManager.removeItemWith(url: url)
        recordings.removeAll(where: {$0.fileURL == url})
        configureIfLibraryIsEmpty()
        libraryCollectionView.reloadData()
    }
    
}
