//
//  AssetWriterError.swift
//  Revo
//
//  Created by Waylan Sands on 12/1/21.
//

import Foundation

enum AssetWriterError: LocalizedError {
    case emptyVideoTracks
    case videoWriterError
    case videoInputError
    case micInputError
    case bufferError
    case exportError
    
    var errorDescription: String? {
        switch self {
        case .emptyVideoTracks:
        return "Sorry the AVAsset had a hard time finding a track from the recording, close the app and try again."
        case .videoWriterError:
        return "Sorry the Video write had a hard time composing the video, please close the app and try again."
        case .videoInputError:
        return "Sorry the app could not connect to your camera device, please close the app and try again."
        case .micInputError:
        return "Sorry the app could not connect to your microphone device, please close the app and try again."
        case .bufferError:
        return "Sorry the app had a hard time buffering your video, please close the app and try again."
        case .exportError:
        return "Sorry the app was not able to save your video, please close the app and try again."
        }
    }
}
