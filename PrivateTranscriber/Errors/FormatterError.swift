//
//  FormatterError.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/07/17.
//

import Foundation

enum FormatterError: Error, LocalizedError {
    case modelNotAvailable

    var errorDescription: String? {
        switch self {
        case .modelNotAvailable:
            return "Model is not available"
        }
    }
}
