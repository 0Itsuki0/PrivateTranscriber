//
//  InsertTextError.swift
//  Swifly
//
//  Created by Itsuki on 2025/12/23.
//

import Foundation

public enum InsertTextError: Error, LocalizedError {
    case unsettableElement
    case unsettableApp
    case failToCopyPaste(reason: String?)

    public var errorDescription: String? {
        switch self {
        case .unsettableElement:
            "No focused input field found"
        case .unsettableApp:
            "Target application does not support text insertion via Accessibility API"
        case .failToCopyPaste(let reason):
            "Failed to simulate copy and paste. \(reason, default: "")"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .unsettableElement:
            "Please copy from the menu."
        case .unsettableApp, .failToCopyPaste:
            "Transcription was copied to clipboard and a paste command was simulated."
        }
    }
}
