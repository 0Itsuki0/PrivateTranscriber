//
//  RecordingError.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/07/17.
//

import Foundation

enum RecordingError: Error, LocalizedError {
    case permissionDenied
    case micNotFound

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Audio recording permission is denied."
        case .micNotFound:
            "Microphone is not found."
        }
    }
}
