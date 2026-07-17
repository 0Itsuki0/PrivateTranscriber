//
//  AccessibilityError.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2025/12/21.
//

import Cocoa

enum AccessibilityError: String, Error, LocalizedError {
    case accessibilityPermissionNotGranted

    // MARK: - AXError mapped
    // AXError.failure
    case generalFailure
    case illegalArgument
    case invalidUIElement
    case invalidUIElementObserver
    case cannotComplete
    case attributeUnsupported
    case actionUnsupported
    case notificationUnsupported
    case notImplemented
    case notificationAlreadyRegistered
    case notificationNotRegistered
    case apiDisabled
    case noValue
    case parameterizedAttributeUnsupported
    case notEnoughPrecision

    var recoverySuggestion: String? {
        switch self {
        case .accessibilityPermissionNotGranted:
            "Open System Settings → Privacy & Security → Accessibility and enable PrivateTranscriber, then try again."
        default:
            // The non-permission AX errors are silently swallowed by
            // `handleError` (they fire constantly during AX-tree walks
            // on apps with broken AX, e.g. Electron). They never reach
            // the overlay; the suggestion text exists only for logs.
            nil
        }
    }

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionNotGranted:
            "Accessibility access is denied."
        default:
            "Something went wrong with Accessibility API: \(self.rawValue)"
        }
    }

    init?(_ axError: AXError) {
        switch axError {
        case .success:
            return nil
        case .failure:
            self = .generalFailure
        case .illegalArgument:
            self = .illegalArgument
        case .invalidUIElement:
            self = .invalidUIElement
        case .invalidUIElementObserver:
            self = .invalidUIElementObserver
        case .cannotComplete:
            self = .cannotComplete
        case .attributeUnsupported:
            self = .attributeUnsupported
        case .actionUnsupported:
            self = .actionUnsupported
        case .notificationUnsupported:
            self = .notificationUnsupported
        case .notImplemented:
            self = .notImplemented
        case .notificationAlreadyRegistered:
            self = .notificationAlreadyRegistered
        case .notificationNotRegistered:
            self = .notificationNotRegistered
        case .apiDisabled:
            self = .apiDisabled
        case .noValue:
            self = .noValue
        case .parameterizedAttributeUnsupported:
            self = .parameterizedAttributeUnsupported
        case .notEnoughPrecision:
            self = .notEnoughPrecision
        @unknown default:
            self = .generalFailure
        }
    }

}
