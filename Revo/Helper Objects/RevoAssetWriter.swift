//
//  RevoAssetWriter.swift
//  Revo
//
//  Created by Waylan Sands on 18/12/20.
//

import Foundation
import AVFoundation
import ReplayKit

class RevoAssetWriter {
    // For writing video
    private var videoOutputURL: URL
    private var videoWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    
    // For writing  audio
    private var audioOutputURL: URL
    private var audioWriter: AVAssetWriter?
    private var micAudioInput:AVAssetWriterInput?
    
    private var isVideoWritingFinished = false
    private var isAudioWritingFinished = false
    
    private var sessionStartTime: CMTime = CMTime.zero
    var rotationAngle: CGFloat = 0
    
    init() {
        let documentsPath = FileManager.documentsDirectoryURL()
        self.videoOutputURL = documentsPath.appendingPathComponent("RPScreenWriterVideo.mov")
        self.audioOutputURL = documentsPath.appendingPathComponent("RPScreenWriterAudio.mov")
        removeURLsIfNeeded()
    }
    
    private func removeURLsIfNeeded() {
        FileManager.removeItemWith(url:  self.videoOutputURL)
        FileManager.removeItemWith(url:  self.audioOutputURL)
    }
    
    func resetWriter() {
        removeURLsIfNeeded()
        isVideoWritingFinished = false
        isAudioWritingFinished = false
        videoInput = nil
        videoWriter = nil
        micAudioInput = nil
        audioWriter = nil
    }
    
    func setUpWriter() throws {
        removeURLsIfNeeded()
        resetWriter()
       
        try videoWriter = AVAssetWriter(outputURL: self.videoOutputURL, fileType: .mov)
        
        let videoSettings: [String : Any] = [
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
            AVVideoHeightKey : UIScreen.main.bounds.height * 2,
            AVVideoWidthKey  : UIScreen.main.bounds.width * 2,
        ]
        
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        
        if let videoInput = self.videoInput, let canAddInput = videoWriter?.canAdd(videoInput), canAddInput {
            // Video will be rotated to reflect device orientation
            videoInput.transform = CGAffineTransform(rotationAngle: rotationAngle)
            videoWriter?.add(videoInput)
        } else {
            print("couldn't add video input")
            throw AssetWriterError.videoInputError
        }
        
        try audioWriter = AVAssetWriter(outputURL: self.audioOutputURL, fileType: .mov)
        
        var channelLayout = AudioChannelLayout()
        channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_MPEG_2_0
        
        let audioOutputSettings: [String : Any] = [
            AVNumberOfChannelsKey : 2,
            AVFormatIDKey : kAudioFormatMPEG4AAC_HE,
            AVSampleRateKey : 44100,
            AVChannelLayoutKey : NSData(bytes: &channelLayout, length: MemoryLayout.size(ofValue: channelLayout))
        ]
        
        micAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioOutputSettings)
        if let micAudioInput = self.micAudioInput, let canAddInput = audioWriter?.canAdd(micAudioInput),
           canAddInput {
            audioWriter?.add(micAudioInput)
        } else {
            print("couldn't add mic audio input")
            throw AssetWriterError.micInputError
        }
        
    }
    
    func writeBuffer(_ cmSampleBuffer: CMSampleBuffer, rpSampleType: RPSampleBufferType, completion: @escaping (AssetWriterError?) -> Void) {
    
        guard let videoWriter = self.videoWriter, let audioWriter = self.audioWriter else {
            completion(AssetWriterError.videoWriterError)
            return
        }
        
        let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(cmSampleBuffer)
        
        switch rpSampleType {
        case .video:
            if videoWriter.status == .unknown {
                if videoWriter.startWriting() {
                    print("Started writing video")
                    self.sessionStartTime = presentationTimeStamp
                    videoWriter.startSession(atSourceTime: presentationTimeStamp)
                }
            } else if videoWriter.status == .writing {
                if let isReadyForMoreMediaData = videoInput?.isReadyForMoreMediaData, isReadyForMoreMediaData {
                    if let appendInput = videoInput?.append(cmSampleBuffer),
                       !appendInput {
                        // Couldn't write video buffer
                        completion(AssetWriterError.bufferError)
                    }
                }
            }
        case .audioMic:
            if audioWriter.status == .unknown {
                if audioWriter.startWriting() {
                    print("Started writing audio")
                    audioWriter.startSession(atSourceTime: presentationTimeStamp)
                }
            } else if audioWriter.status == .writing {
                if let isReadyForMoreMediaData = micAudioInput?.isReadyForMoreMediaData,
                   isReadyForMoreMediaData {
                    if let appendInput = micAudioInput?.append(cmSampleBuffer),
                       !appendInput {
                        print("couldn't write audio buffer")
                    }
                }
            }
        default:
            break
        }
        completion(nil)
    }
    
    func finishWriting(completionHandler handler: @escaping (URL?, AssetWriterError?) -> Void) {
       
        self.videoInput?.markAsFinished()
        self.videoWriter?.finishWriting {
            self.isVideoWritingFinished = true
            completion()
        }
        
        if audioWriter!.status == .unknown {
            // User selected RPScreenRecorder's "Record Screen Only" action (not microphone)
            // therefore we mark isAudioWritingFinished as true and disregard marking
            // micAudioInput as finished.
            self.isAudioWritingFinished = true
        } else {
            self.micAudioInput?.markAsFinished()
            self.audioWriter?.finishWriting {
                self.isAudioWritingFinished = true
                completion()
            }
        }
        
        func completion() {
            if self.isVideoWritingFinished && self.isAudioWritingFinished {
                self.isVideoWritingFinished = false
                self.isAudioWritingFinished = false
                self.videoInput = nil
                self.videoWriter = nil
                self.micAudioInput = nil
                self.audioWriter = nil
                merge()
            }
        }
        
        func merge() {
            let mergeComposition = AVMutableComposition()
            
            let videoAsset = AVAsset(url: self.videoOutputURL)
            let videoTracks = videoAsset.tracks(withMediaType: .video)
                
            guard let firstTrack = videoTracks.first else {
                print("firstTrack fail")
                handler(nil, AssetWriterError.emptyVideoTracks)
                return
            }
            
            let videoCompositionTrack = mergeComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try videoCompositionTrack?.insertTimeRange(CMTimeRange(start: CMTime.zero, end: videoAsset.duration),  of: firstTrack, at: CMTime.zero)
            } catch {
                print("videoCompositionTrack fail")
                handler(nil, AssetWriterError.emptyVideoTracks)
            }

            videoCompositionTrack?.preferredTransform = videoTracks.first!.preferredTransform
            
            let audioAsset = AVAsset(url: self.audioOutputURL)
            let audioTracks = audioAsset.tracks(withMediaType: .audio)
            
            for audioTrack in audioTracks {
                let audioCompositionTrack = mergeComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                do {
                    try audioCompositionTrack?.insertTimeRange(CMTimeRange(start: CMTime.zero, end: audioAsset.duration), of: audioTrack, at: CMTime.zero)
                } catch let error {
                    print(error)
                }
            }
            let fileName = String(Date().timeIntervalSince1970)
            let documentsURL = FileManager.documentsDirectoryURL()
            let fileURL = documentsURL.appendingPathComponent(fileName).appendingPathExtension("mov")
            
            let exportSession = AVAssetExportSession(asset: mergeComposition, presetName: AVAssetExportPresetHighestQuality)
            exportSession?.outputFileType = .mov
            exportSession?.shouldOptimizeForNetworkUse = false
            exportSession?.outputURL = fileURL
            exportSession?.exportAsynchronously {
                if let _ = exportSession?.error {
                    print("exportSession fail")
                    handler(nil, AssetWriterError.exportError)
                } else {
                    self.removeURLsIfNeeded()
                    handler(exportSession?.outputURL, nil)
                }
            }
        }
    }
}
