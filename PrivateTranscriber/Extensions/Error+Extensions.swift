//
//  Error+Extensions.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/05/11.
//

import Foundation

nonisolated extension Error {
    var recoverySuggestion: String? {
        return (self as? LocalizedError)?.recoverySuggestion
    }

    var isCancellationError: Bool {
        self is CancellationError
    }
}
