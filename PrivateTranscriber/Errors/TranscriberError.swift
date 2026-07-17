//
//  TranscriberError.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/07/17.
//

import Foundation

enum TranscriberError: Error, LocalizedError {
    case failToSetup
    case targetTranscriberNotFound
    
    var localizedDescription: String {
        switch self {
        case .failToSetup:
            return "Failed to setup transcriber."
        case .targetTranscriberNotFound:
            return "Transcriber not found for the select locale."
        }
    }
}
