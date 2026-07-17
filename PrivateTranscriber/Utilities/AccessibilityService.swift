//
//  AccessibilityService.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/07/01.
//

import AppKit

nonisolated private let category = "AccessibilityService"
nonisolated private let logger = Logger.shared

nonisolated enum AccessibilityService {

    static let settingURL = URL(
        string:
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
    )

    static func openAccessibilitySettings() {
        if let url = AccessibilityService.settingURL {
            NSWorkspace.shared.open(url)
        }
    }

    static func checkAccessibilityPermission() throws {
        try self.requestPermissionHelper(displayPrompt: false)
    }

    static func requestAccessibilityPermission() {
        // not throwing here because this is intended to be called to prompt for permission instead of showing error
        try? self.requestPermissionHelper(displayPrompt: true)
    }

    private static func requestPermissionHelper(displayPrompt: Bool) throws {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String:
                displayPrompt
        ]

        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            throw AccessibilityError.accessibilityPermissionNotGranted
        }
    }
}

nonisolated
    extension AccessibilityService
{
    static func findFocusedUIElement() throws -> AXUIElement {
        let focusedAXElement = try self.getElementValueForAttribute(
            on: AXUIElementCreateSystemWide(),
            attribute: kAXFocusedUIElementAttribute
        )
        return focusedAXElement
    }

    static func findFocusedApplication() throws -> AXUIElement {
        let focusedAXElement = try self.getElementValueForAttribute(
            on: AXUIElementCreateSystemWide(),
            attribute: kAXFocusedApplicationAttribute
        )
        return focusedAXElement
    }

    static func getCurrentValue(_ element: AXUIElement) throws -> String {
        return try self.getStringValueForAttribute(
            on: element,
            attribute: kAXValueAttribute
        )
    }

    static func getElementRole(_ element: AXUIElement) throws -> String {
        return try self.getStringValueForAttribute(
            on: element,
            attribute: kAXRoleAttribute
        )
    }

    static func getElementChildren(_ element: AXUIElement) throws
        -> [AXUIElement]
    {
        guard
            let value = try self.getTypeRefForAttribute(
                on: element,
                attribute: kAXChildrenAttribute
            ) as? [AXUIElement]
        else {
            throw AccessibilityError.generalFailure
        }

        return value

    }

    static func getSelectedTextRange(
        _ element: AXUIElement
    ) throws -> CFRange {

        let value = try self.getTypeRefForAttribute(
            on: element,
            attribute: kAXSelectedTextRangeAttribute
        )

        var range = CFRange(location: 0, length: 0)
        // force wrapping required.
        // conditional wrapping won't compile: with the error Conditional downcast to CoreFoundation type 'AXValue' will always succeed
        let result = AXValueGetValue(value as! AXValue, .cfRange, &range)
        if !result {
            throw AccessibilityError.generalFailure
        }
        return range
    }

    static func getStringForRange(
        _ element: AXUIElement,
        range: CFRange
    ) throws -> String {
        var range = range
        guard let rangeValue = AXValueCreate(.cfRange, &range) else {
            throw AccessibilityError.generalFailure
        }

        var value: CFTypeRef?

        let error = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXStringForRangeParameterizedAttribute as CFString,
            rangeValue,
            &value
        )

        try checkAXError(error)
        guard let value else {
            throw AccessibilityError.generalFailure
        }

        if let string = value as? String {
            return string
        }

        return ""
    }
}

// MARK: - Set Value Helpers
nonisolated extension AccessibilityService {
    static func setAttribute(
        _ element: AXUIElement,
        _ attribute: String,
        _ value: CFTypeRef
    ) throws {
        let setAttributeResult = AXUIElementSetAttributeValue(
            element,
            attribute as CFString,
            value
        )

        try checkAXError(setAttributeResult)
    }
}

// MARK: - Get Value Helpers
nonisolated extension AccessibilityService {
    static func getTypeRefForAttribute(
        on element: AXUIElement,
        attribute: String
    ) throws -> CFTypeRef {
        var value: CFTypeRef?

        let error = AXUIElementCopyAttributeValue(
            element,
            attribute as CFString,
            &value
        )

        try checkAXError(error)

        guard let value else {
            throw AccessibilityError.generalFailure
        }

        return value
    }

    static func getElementValueForAttribute(
        on element: AXUIElement,
        attribute: String
    ) throws -> AXUIElement {

        guard
            let value = try self.getTypeRefForAttribute(
                on: element,
                attribute: attribute
            ) as! AXUIElement?
        else {
            throw AccessibilityError.generalFailure
        }

        return value
    }

    static func getStringValueForAttribute(
        on element: AXUIElement,
        attribute: String
    ) throws -> String {

        guard
            let valueString = try self.getTypeRefForAttribute(
                on: element,
                attribute: attribute
            ) as? String
        else {
            throw AccessibilityError.generalFailure
        }

        return valueString
    }

}

// MARK: - Check Error
nonisolated extension AccessibilityService {
    static func checkAXError(_ error: AXError) throws {
        if let error = AccessibilityError(error) {
            throw error
        }
    }
}
