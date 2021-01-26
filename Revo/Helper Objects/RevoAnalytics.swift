//
//  RevoAnalytics.swift
//  Revo
//
//  Created by Waylan Sands on 25/1/21.
//

import UIKit
import FirebaseAnalytics

struct RevoAnalytics {
    
    static func editedSplitScreenStyle() {
        Analytics.logEvent("edited_splitScreen_style", parameters: nil)
    }
    
    static func editedPipStyle() {
        Analytics.logEvent("edited_pip_style", parameters: nil)
    }
    
    static func logWatermarkRemoval() {
        Analytics.logEvent("watermark_removed", parameters: nil)
    }
    
    static func logAppStoreReview() {
        Analytics.logEvent("app_store_review", parameters: nil)
    }
    
    static func logLandscapeVideo() {
        Analytics.logEvent("landscape_video", parameters: nil)
    }
    
    static func videoActivityCompletedWith(activity: UIActivity.ActivityType) {
        
        switch activity {
        case .airDrop:
            Analytics.logEvent("sent_via_airDrop", parameters: nil)
        case .mail:
            Analytics.logEvent("sent_via_mail", parameters: nil)
        case .message:
            Analytics.logEvent("sent_via_message", parameters: nil)
        case .postToFacebook:
            Analytics.logEvent("posted_to_facebook", parameters: nil)
        case .postToTwitter:
            Analytics.logEvent("posted_to_Twitter", parameters: nil)
        case .postToVimeo:
            Analytics.logEvent("posted_to_Vimeo", parameters: nil)
        case .saveToCameraRoll:
            Analytics.logEvent("saved_to_camera_roll", parameters: nil)
        default:
            Analytics.logEvent("shared_video", parameters: nil)
        }
    }
    
    static func linkActivityCompletedWith(activity: UIActivity.ActivityType) {
        
        switch activity {
        case .airDrop:
            Analytics.logEvent("app_shared_via_airDrop", parameters: nil)
        case .mail:
            Analytics.logEvent("app_shared_via_mail", parameters: nil)
        case .message:
            Analytics.logEvent("app_shared_via_message", parameters: nil)
        case .postToFacebook:
            Analytics.logEvent("app_shared_to_facebook", parameters: nil)
        case .postToTwitter:
            Analytics.logEvent("app_posted_to_Twitter", parameters: nil)
        case .postToVimeo:
            Analytics.logEvent("app_posted_to_Vimeo", parameters: nil)
        default:
            Analytics.logEvent("shared_app", parameters: nil)
        }
    }
    
    static func logRecordingEvent(in recordingMode: RecordingMode, using presentation: PresentationMode) {
        
        var presentationModeString = ""
        var recordingModeString = ""
        
        switch recordingMode {
        case .video:
            recordingModeString = "recorded_in_"
        case .live:
            recordingModeString = "broadcast_"
        }
        
        switch presentation {
        case .splitScreen:
            presentationModeString = "splitScreen_mode"
        case .switchCam:
            presentationModeString = "switchCam_mode"
        case .pip:
            presentationModeString = "pip_mode"
        case .web:
            break
        }
        
        Analytics.logEvent(recordingModeString + presentationModeString, parameters: nil)

    }
    
    static func logScreenView(for screenName: String, ofClass screenClass: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters:
                            [AnalyticsParameterScreenName : screenName,
                             AnalyticsParameterScreenClass : screenClass
                            ])
    }
    
    
}
