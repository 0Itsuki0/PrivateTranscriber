//
//  TextInserter.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2025/12/21.
//

// For using Virtual Key definitions
import Carbon
import Cocoa
import Foundation

nonisolated private let category = "TextInserter"
nonisolated private let logger = Logger.shared

// AXError needs to be thrown in a nonisolated context.
// Otherwise the app will freeze
nonisolated enum TextInserter {

    // NOTE:
    // kAXComboBoxRole's value COULD be set using the kAXValueAttribute.
    // However, there are couple problems with setting this property.
    // 1. It will REPLACE the value with what we set. We could get the value and append the new one to it, but that will ignore the cursor's position. This is different from a text element where when we set the kAXSelectedTextAttribute, it will automatically insert the text based on the cursor's position
    // 2. It is not guaranteed that a combo box is actually a text entry.
    private static let textElementRoles: Set<String> = [
        kAXTextFieldRole, kAXTextAreaRole,
    ]

    static func insertText(_ text: String) throws {
        do {
            try self._insertText(text)
            return
        } catch {
            logger.error(
                category: category,
                message:
                    "Error inserting Text using accessibility API: \(error.localizedDescription)"
            )
        }

        do {
            try self.simulateCopyPaste(text)
        } catch {
            logger.error(
                category: category,
                message:
                    "Error inserting Text using CopyPaste:: \(error.localizedDescription)"
            )
            throw error
        }
    }

    static private func _insertText(_ text: String) throws {
        let focusedAXElement = try AccessibilityService.findFocusedUIElement()

        try AccessibilityService.checkAccessibilityPermission()

        let role = try AccessibilityService.getElementRole(focusedAXElement)

        if !textElementRoles.contains(role) {
            throw InsertTextError.unsettableElement
        }

        // setting kAXSelectedTextAttribute will insert the text based on the cursor's position
        // only work for kAXTextFieldRole, kAXTextAreaRole?
        // even we cannot insert into it, for example, if the current focus is combo box, we won't get an error either. That's why we are checking to see if the value actually changed.

        let currentValue = try AccessibilityService.getCurrentValue(
            focusedAXElement
        )

        try AccessibilityService.setAttribute(
            focusedAXElement,
            kAXSelectedTextAttribute,
            text as CFTypeRef
        )

        let newValue = try AccessibilityService.getCurrentValue(
            focusedAXElement
        )
        // for applications such as Google Doc or VSCode,
        // the role is TextArea, the kAXSelectedTextAttribute is Settable, we get a success when calling AXUIElementSetAttributeValue
        // however, the actual value will not be updated, possibly due to those system handle text in a specific way, for example, with some kinds of format.
        if currentValue == newValue {
            throw InsertTextError.unsettableApp
        }

    }

    static func simulateCopyPaste(_ text: String) throws {
        // We cannot use A private paste board here because it will not be accessible through the paste command
        let pasteboard = NSPasteboard.general
        //  save the current content to avoid resetting the contents of the general one
        let currentContent = pasteboard.string(forType: .string)
        defer {
            if let currentContent {
                Task.detached(operation: {
                    // a little wait after setting it back.
                    // Otherwise, the paste command will reflect the current content instead
                    try? await Task.sleep(for: .milliseconds(200))
                    let pasteboard = NSPasteboard.general
                    pasteboard.declareTypes([.string], owner: nil)
                    pasteboard.setString(currentContent, forType: .string)
                })
            }
        }
        // not using clearContents to avoid clearing other types
        pasteboard.declareTypes([.string], owner: nil)
        let result = pasteboard.setString(text, forType: .string)
        if !result {
            throw InsertTextError.failToCopyPaste(reason: nil)
        }
        try self.simulateKeyDown(key: CGKeyCode(kVK_ANSI_V), with: .maskCommand)
    }

    static private func simulateKeyDown(
        key: CGKeyCode,
        with flags: CGEventFlags
    ) throws {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            throw InsertTextError.failToCopyPaste(
                reason: "Failed to create CGEventSource"
            )
        }

        // Key down event
        guard
            let keyDownEvent = CGEvent(
                keyboardEventSource: source,
                virtualKey: key,
                keyDown: true
            )
        else {
            throw InsertTextError.failToCopyPaste(
                reason: "Failed to create key down event"
            )
        }
        keyDownEvent.flags = flags

        // .cghidEventTap may silently stops working after a macOS update, ie:, when a new macOS update tightened security around synthetic HID events. CGEvent.post(tap: .cghidEventTap) injects at the lowest HID level and newer macOS versions have been progressively restricting this for apps posting synthetic input. The events are created fine but silently dropped before reaching the session.
        // .cgAnnotatedSessionEventTap post at the session level, which is still permitted for accessibility-trusted apps.
        keyDownEvent.post(tap: .cgAnnotatedSessionEventTap)

        // Key up event
        guard
            let keyUpEvent = CGEvent(
                keyboardEventSource: source,
                virtualKey: key,
                keyDown: false
            )
        else {
            throw InsertTextError.failToCopyPaste(
                reason: "Failed to create key up event"
            )
        }
        keyUpEvent.flags = flags
        keyUpEvent.post(tap: .cgAnnotatedSessionEventTap)
    }

}
