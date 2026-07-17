//
//  TranscriptionActivationType.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/07/17.
//

import Foundation

nonisolated enum TranscriptionActivationType: String, Identifiable,
    CaseIterable, Hashable,
    Equatable
{
    case hold
    case tap

    var id: String { rawValue }
    var title: String {
        switch self {
        case .hold:
            "Hold to record"
        case .tap:
            "Tap to start and stop"
        }
    }
}
