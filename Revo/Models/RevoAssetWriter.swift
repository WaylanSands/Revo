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
    var videoOutputURL: URL
    var videoWriter: AVAssetWriter?
    var videoInput: AVAssetWriterInput?
    
    // For writing  audio
    var audioOutputURL: URL
    var audioWriter: AVAssetWriter?
    var micAudioInput:AVAssetWriterInput?
    
    var isVideoWritingFinished = false
    var isAudioWritingFinished = false
    var isPaused: Bool = false
    
    var sessionStartTime: CMTime = CMTime.zero
    var currentTime: CMTime = CMTime.zero
    
    var rotationAngle: CGFloat = 0
    
    init() {
        let documentsPath = FileManager.documentsDirectoryURL()
        self.videoOutputURL = documentsPath.appendingPathComponent("RPScreenWriterVideo.mov")
        self.audioOutputURL = documentsPath.appendingPathComponent("RPScreenWriterAudio.mov")
        removeURLsIfNeeded()
    }
    
    func removeURLsIfNeeded() {
        FileManager.removeItemWith(url:  self.videoOutputURL)
        FileManager.removeItemWith(url:  self.audioOutputURL)
    }
    
    func resetWriter() {
        removeURLsIfNeeded()
        isVideoWritingFinished = false
        isAudioWritingFinished = false
        isPaused = false
        videoInput = nil
        videoWriter = nil
        micAudioInput = nil
        audioWriter = nil
    }
    
    func setUpWriter() {
        do {
            try videoWriter = AVAssetWriter(outputURL: self.videoOutputURL, fileType: .mov)
        } catch let writerError as NSError {
            print("Error opening video file \(writerError)")
        }
        
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
        }
        
        do {
            try audioWriter = AVAssetWriter(outputURL: self.audioOutputURL, fileType: .mov)
        } catch let writerError as NSError {
            print("Error opening video file \(writerError)")
        }
        
        var channelLayout = AudioChannelLayout()
        channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_MPEG_5_1_D
        let audioOutputSettings = [
            AVNumberOfChannelsKey : 6,
            AVFormatIDKey : kAudioFormatMPEG4AAC_HE,
            AVSampleRateKey : 44100,
            AVChannelLayoutKey : NSData(bytes: &channelLayout, length: MemoryLayout.size(ofValue: channelLayout))
        ] as [String : Any]
        
        micAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioOutputSettings)
        if let micAudioInput = self.micAudioInput,
           let canAddInput = audioWriter?.canAdd(micAudioInput),
           canAddInput {
            audioWriter?.add(micAudioInput)
        } else {
            print("couldn't add mic audio input")
        }
        
    }
    
    func writeBuffer(_ cmSampleBuffer: CMSampleBuffer, rpSampleType: RPSampleBufferType) {
        
        if self.videoWriter == nil {
            DispatchQueue.main.async {
                self.setUpWriter()
            }
        }
        
        guard let videoWriter = self.videoWriter, let audioWriter = self.audioWriter, !isPaused else {
            return
        }
        
        let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(cmSampleBuffer)
        
        switch rpSampleType {
        case .video:
            if videoWriter.status == .unknown {
                if videoWriter.startWriting() {
                    print("video writing started")
                    self.sessionStartTime = presentationTimeStamp
                    videoWriter.startSession(atSourceTime: presentationTimeStamp)
                }
            } else if videoWriter.status == .writing {
                if let isReadyForMoreMediaData = videoInput?.isReadyForMoreMediaData,
                   isReadyForMoreMediaData {
                    self.currentTime = CMTimeSubtract(presentationTimeStamp, self.sessionStartTime)
                    if let appendInput = videoInput?.append(cmSampleBuffer),
                       !appendInput {
                        print("couldn't write video buffer")
                    }
                }
            }
        case .audioMic:
            if audioWriter.status == .unknown {
                if audioWriter.startWriting() {
                    print("audio writing started")
                    audioWriter.startSession(atSourceTime: presentationTimeStamp)
                }
            } else if audioWriter.status == .writing {
                if let isReadyForMoreMediaData = micAudioInput?.isReadyForMoreMediaData,
                   isReadyForMoreMediaData {
                    if let appendInput = micAudioInput?.append(cmSampleBuffer),
                       !appendInput {
                        print("couldn't write mic audio buffer")
                    }
                }
            }
        default:
            break
        }
    }
    
    func finishWriting(completionHandler handler: @escaping (URL?, Error?) -> Void) {
       
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
                self.isPaused = false
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
            
            // This is returned late or not at all when merge fails
            // need more investigation
            videoAsset.loadValuesAsynchronously(forKeys: ["playable", "tracks"]) {
                print("Returned loadValuesAsynchronously")
            }
            
            let videoTracks = videoAsset.tracks(withMediaType: .video)
                
            guard let firstTrack = videoTracks.first else {
                // Todo: Figure why videoTracks is sometimes empty
                // Create propper error handling
                handler(nil, nil)
                return
            }
            
            let videoCompositionTrack = mergeComposition.addMutableTrack(withMediaType: .video,
                                                                         preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try videoCompositionTrack?.insertTimeRange(CMTimeRange(start: CMTime.zero, end: videoAsset.duration),
                                                           of: firstTrack,
                                                           at: CMTime.zero)
            } catch let error {
                self.removeURLsIfNeeded()
                handler(nil, error)
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
                if let error = exportSession?.error {
                    self.removeURLsIfNeeded()
                    handler(nil, error)
                } else {
                    self.removeURLsIfNeeded()
                    handler(exportSession?.outputURL, nil)
                }
            }
        }
    }
}
