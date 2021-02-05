//
//  RevoImages.swift
//  Revo
//
//  Created by Waylan Sands on 3/12/20.
//

import UIKit

struct RevoImages {
    
    // RecordingControlsVC 
    static let switchFullScreenPreview = UIImage(named: "switch_preview_mode_icon")
    static let cancelEditPreviewIcon = UIImage(named: "cancel_edit_preview_icon")
    static let splitScreenIcon = UIImage(named: "split_screen_mode_icon")
    static let multiScreenIcon = UIImage(named: "pip_screen_mode_icon")
    static let switchPreviews = UIImage(named: "switch_previews_icon")
    static let editPreviewIcon = UIImage(named: "edit_preview_icon")
    static let liveButtonIcon = UIImage(named: "live_button_icon")
    static let flashOffIcon = UIImage(named: "flash_off_icon")
    static let settingsIcon = UIImage(named: "settings_icon")
    static let flashOnIcon = UIImage(named: "flash_on_icon")
    static let libraryIcon = UIImage(named: "library_icon")
    static let webIcon = UIImage(named: "web_preview_icon")
    static let zoomIcon = UIImage(named: "zoom_icon")
    static let infoIcon = UIImage(named: "info_icon")
    static let isoIcon = UIImage(named: "iso_icon")
    
    // SF Symbols
    static func cameraIcon() -> UIImage? {
        if #available(iOS 13.0, *) {
            let imageSize = UIFont.systemFont(ofSize: 32, weight: .regular)
            let configuration = UIImage.SymbolConfiguration(font: imageSize)
            return UIImage(systemName: "camera.aperture", withConfiguration: configuration)
        } else {
            return UIImage(named: "record_button_icon")
        }
    }
    
    // LibraryVC
    static let whiteDownArrow = UIImage(named: "white_down_arrow_Icon")
    static let blackDownArrow = UIImage(named: "down_arrow_icon")
    static let selectionIcon = UIImage(named: "selection_icon")
    
    // RecordingOptionsView
    static let deleteIcon = UIImage(named: "delete_icon")
    static let shareIcon = UIImage(named: "share_icon")
    
    // TopPreviewOptionsView
    static let whiteBackArrowIcon = UIImage(named: "white_back_arrow")
    static let audioOffIcon = UIImage(named: "audio_off_icon")
    static let audioOnIcon = UIImage(named: "audio_on_icon")
    
    // SettingsVC
    static let blackShareIcon = UIImage(named: "black_share_icon")
    static let blackAppIcon = UIImage(named: "black_app_icon")
    static let mailIcon = UIImage(named: "mail_icon")
    
    // WebVC
    static let hideControls = UIImage(named: "hide_controls_icon")
    static let showControls = UIImage(named: "show_controls_icon")

    // WebToolBarView
    static let backWebButton = UIImage(named: "back_web_icon")
    static let forwardWebButton = UIImage(named: "forward_web_icon")
    
    // RevoVideoPlayer
    static let pauseIcon = UIImage(named: "pause_icon")
    static let playIcon = UIImage(named: "play_icon")
    
    // UploadVC
    static let blackUploadIcon = UIImage(named: "black_upload_icon")
    static let whiteUploadIcon = UIImage(named: "white_upload_icon")
    static let aspectFitIcon = UIImage(named: "aspect_fit_icon")
    static let aspectFillIcon = UIImage(named: "aspect_fill_icon")
    static let smallAudioOffIcon = UIImage(named: "small_audio_off_icon")
    static let smallAudioIcon = UIImage(named: "small_audio_icon")
    static let rotateIcon = UIImage(named: "rotate_icon")
    static let miniPauseIcon = UIImage(named: "mini_pause_icon")
    static let miniPlayIcon = UIImage(named: "mini_play_icon")


    

}


