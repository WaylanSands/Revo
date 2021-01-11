//
//  LibraryViewCell.swift
//  Revo
//
//  Created by Waylan Sands on 8/12/20.
//

import UIKit

protocol RecordingViewCellDelegate: class {
    func appendSelectedRecordingWith(fileURL: URL)
    func removeSelectedRecordingWith(fileURL: URL)
}

class RecordingViewCell: UICollectionViewCell {
    
    var recording: Recording!
    
    var selectionState: SelectionState = .inactive
    weak var recordingCellDelegate: RecordingViewCellDelegate?
    
    var selectedImageView: UIImageView  = {
       let imageView = UIImageView()
        imageView.backgroundColor = RevoColor.recordingSelection
        imageView.image = RevoImages.selectionIcon
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 12
        imageView.isHidden = true
        return imageView
    }()
    
    let sizeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    let thumbnailImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
            
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
        configureViews()
    }
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupCellWith(recording: Recording) {
        self.recording = recording
        
        if let image = recording.thumbnail {
            self.thumbnailImageView.image = image
        } else {
            self.thumbnailImageView.image = UIImage.thumbnailFromMovie(url: recording.fileURL)
            backgroundColor = .gray
        }
        
        sizeLabel.text = recording.fileURL.fileSizeString
        timeLabel.text = recording.duration
        
        if recording.isImage {
            timeLabel.isHidden = true
        } else {
            timeLabel.isHidden = false
        }
    }
    
    func configureViews() {
        self.addSubview(thumbnailImageView)
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        thumbnailImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        thumbnailImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        thumbnailImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        self.addSubview(selectedImageView)
        selectedImageView.translatesAutoresizingMaskIntoConstraints = false
        selectedImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
        selectedImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10).isActive = true
        selectedImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        selectedImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        
        self.addSubview(sizeLabel)
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        sizeLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
        sizeLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10).isActive = true
        
        self.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
        timeLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
    }
        
    @objc func selectLibraryCell() {
        switch selectionState {
        case .active:
            selectionState = .inactive
            makeInActive()
        case .inactive:
            selectionState = .active
            makeActive()
        }
    }
    
    func makeActive() {
        selectedImageView.isHidden = false
        recordingCellDelegate?.appendSelectedRecordingWith(fileURL: recording.fileURL)
    }
    
    func makeInActive() {
        recordingCellDelegate?.removeSelectedRecordingWith(fileURL: recording.fileURL)
        selectedImageView.isHidden = true
        selectionState = .inactive
    }
    
        
}
