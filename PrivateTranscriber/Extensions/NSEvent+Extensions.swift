//
//  NSEvent.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/05/10.
//

import SwiftUI

nonisolated extension NSEvent.ModifierFlags {
    var validModifiers: Self {
        self.intersection([.command, .control, .option, .shift, .function])
    }

    var isValidModifiers: Bool {
        return self.contains(.command) || self.contains(.control)
            || self.contains(.option) || self.contains(.shift) || self.contains(.function)
    }

    var containInvalidModifiers: Bool {
        return self.contains(.capsLock) || self.contains(.help) || self.contains(.numericPad)
    }

    var count: Int {
        return self.symbolRepresentation.count
    }

    var symbolRepresentation: String {
        var parts: [String] = []

        if self.contains(.command) {
            parts.append("⌘")
        }
        if self.contains(.control) {
            parts.append("⌃")
        }
        if self.contains(.option) {
            parts.append("⌥")
        }
        if self.contains(.shift) {
            parts.append("⇧")
        }
        if self.contains(.function) {
            parts.append("🌐︎")
        }

        return parts.joined()
    }
    
    var stringRepresentations: [String] {
        var parts: [String] = []

        if self.contains(.command) {
            parts.append("Cmd")
        }
        if self.contains(.control) {
            parts.append("Ctrl")
        }
        if self.contains(.option) {
            parts.append("Opt")
        }
        if self.contains(.shift) {
            parts.append("Shift")
        }
        if self.contains(.function) {
            parts.append("Fn")
        }
        return parts
    }
}
