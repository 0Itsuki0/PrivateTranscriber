//
//  HotkeyConfiguration.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/06/23.
//

import AppKit
import Carbon

nonisolated struct HotkeyConfiguration: Codable, Equatable {
    var key: UInt16?
    var modifiers: Int
    var key_string: String?

    var modifierFlags: NSEvent.ModifierFlags {
        return .init(rawValue: UInt(modifiers))
    }

    var string_representation: String {
        return
            "\(self.modifierFlags.symbolRepresentation)\(key_string, default: "")"
    }

    var isFnKey: Bool {
        return self.key == nil && self.modifierFlags == .function
    }

    func isTargetKeydown(_ nsEvent: NSEvent) -> Bool {
        let modifiers = nsEvent.modifierFlags.intersection(
            .deviceIndependentFlagsMask
        )

        // Raises an NSInternalInconsistencyException if sent to a non-key event.
        let keyCode = nsEvent.keyCode
        if keyCode == self.key
            && modifiers == self.modifierFlags
        {
            return true
        }

        return false
    }

    func isTargetFlagChange(_ nsEvent: NSEvent) -> Bool {
        let modifiers = nsEvent.modifierFlags.intersection(
            .deviceIndependentFlagsMask
        )
        if modifiers == self.modifierFlags {
            return true
        }
        return false
    }

    init(
        modifierFlags: NSEvent.ModifierFlags,
        key: UInt16?,
        keyChar: String?
    ) {
        self.key = key
        self.modifiers = Int(modifierFlags.rawValue)

        var keyString = keyChar?.uppercased() ?? ""

        switch key {
        case UInt16(kVK_Escape):
            keyString = "Esc"
        case UInt16(kVK_Space):
            keyString = "Space"
        default:
            break
        }

        self.key_string = keyString
    }
}

extension HotkeyConfiguration {
    static let keyCodeStringMap: [Int: String] = [
        // Letters
        kVK_ANSI_A: "A",
        kVK_ANSI_B: "B",
        kVK_ANSI_C: "C",
        kVK_ANSI_D: "D",
        kVK_ANSI_E: "E",
        kVK_ANSI_F: "F",
        kVK_ANSI_G: "G",
        kVK_ANSI_H: "H",
        kVK_ANSI_I: "I",
        kVK_ANSI_J: "J",
        kVK_ANSI_K: "K",
        kVK_ANSI_L: "L",
        kVK_ANSI_M: "M",
        kVK_ANSI_N: "N",
        kVK_ANSI_O: "O",
        kVK_ANSI_P: "P",
        kVK_ANSI_Q: "Q",
        kVK_ANSI_R: "R",
        kVK_ANSI_S: "S",
        kVK_ANSI_T: "T",
        kVK_ANSI_U: "U",
        kVK_ANSI_V: "V",
        kVK_ANSI_W: "W",
        kVK_ANSI_X: "X",
        kVK_ANSI_Y: "Y",
        kVK_ANSI_Z: "Z",

        // Numbers
        kVK_ANSI_0: "0",
        kVK_ANSI_1: "1",
        kVK_ANSI_2: "2",
        kVK_ANSI_3: "3",
        kVK_ANSI_4: "4",
        kVK_ANSI_5: "5",
        kVK_ANSI_6: "6",
        kVK_ANSI_7: "7",
        kVK_ANSI_8: "8",
        kVK_ANSI_9: "9",

        // Punctuation & Symbols
        kVK_ANSI_Equal: "=",
        kVK_ANSI_Minus: "-",
        kVK_ANSI_RightBracket: "]",
        kVK_ANSI_LeftBracket: "[",
        kVK_ANSI_Quote: "'",
        kVK_ANSI_Semicolon: ";",
        kVK_ANSI_Backslash: "\\",
        kVK_ANSI_Comma: ",",
        kVK_ANSI_Slash: "/",
        kVK_ANSI_Period: ".",
        kVK_ANSI_Grave: "`",

        // Keypad
        kVK_ANSI_Keypad0: "Keypad0",
        kVK_ANSI_Keypad1: "Keypad1",
        kVK_ANSI_Keypad2: "Keypad2",
        kVK_ANSI_Keypad3: "Keypad3",
        kVK_ANSI_Keypad4: "Keypad4",
        kVK_ANSI_Keypad5: "Keypad5",
        kVK_ANSI_Keypad6: "Keypad6",
        kVK_ANSI_Keypad7: "Keypad7",
        kVK_ANSI_Keypad8: "Keypad8",
        kVK_ANSI_Keypad9: "Keypad9",
        kVK_ANSI_KeypadDecimal: "Keypad.",
        kVK_ANSI_KeypadMultiply: "Keypad*",
        kVK_ANSI_KeypadPlus: "Keypad+",
        kVK_ANSI_KeypadClear: "KeypadClear",
        kVK_ANSI_KeypadDivide: "Keypad/",
        kVK_ANSI_KeypadEnter: "KeypadEnter",
        kVK_ANSI_KeypadMinus: "Keypad-",
        kVK_ANSI_KeypadEquals: "Keypad=",

        // Function Keys
        kVK_F1: "F1",
        kVK_F2: "F2",
        kVK_F3: "F3",
        kVK_F4: "F4",
        kVK_F5: "F5",
        kVK_F6: "F6",
        kVK_F7: "F7",
        kVK_F8: "F8",
        kVK_F9: "F9",
        kVK_F10: "F10",
        kVK_F11: "F11",
        kVK_F12: "F12",
        kVK_F13: "F13",
        kVK_F14: "F14",
        kVK_F15: "F15",
        kVK_F16: "F16",
        kVK_F17: "F17",
        kVK_F18: "F18",
        kVK_F19: "F19",
        kVK_F20: "F20",

        // Special Keys
        kVK_Return: "Return",
        kVK_Tab: "Tab",
        kVK_Space: "Space",
        kVK_Delete: "Delete",
        kVK_ForwardDelete: "ForwardDelete",
        kVK_Escape: "Escape",
        kVK_CapsLock: "CapsLock",
        kVK_Help: "Help",
        kVK_Home: "Home",
        kVK_End: "End",
        kVK_PageUp: "PageUp",
        kVK_PageDown: "PageDown",
        kVK_ContextualMenu: "Menu",

        // Arrow Keys
        kVK_LeftArrow: "←",
        kVK_RightArrow: "→",
        kVK_UpArrow: "↑",
        kVK_DownArrow: "↓",

        // Modifier Keys
        kVK_Command: "Command",
        kVK_Shift: "Shift",
        kVK_Option: "Option",
        kVK_Control: "Control",
        kVK_RightCommand: "RightCommand",
        kVK_RightShift: "RightShift",
        kVK_RightOption: "RightOption",
        kVK_RightControl: "RightControl",
        kVK_Function: "Fn",

        // Media Keys
        kVK_VolumeUp: "VolumeUp",
        kVK_VolumeDown: "VolumeDown",
        kVK_Mute: "Mute",

        // JIS Keys
        kVK_JIS_Yen: "¥",
        kVK_JIS_Underscore: "_",
        kVK_JIS_KeypadComma: "Keypad,",
        kVK_JIS_Eisu: "Eisu",
        kVK_JIS_Kana: "Kana",

        // ISO Keys
        kVK_ISO_Section: "§",
    ]
}

// MARK: - Default Hotkey: Command + 4
extension HotkeyConfiguration {
    static let `default`: HotkeyConfiguration =
        HotkeyConfiguration(
            modifierFlags: [.function],
            key: nil,
            keyChar: nil
        )
}
