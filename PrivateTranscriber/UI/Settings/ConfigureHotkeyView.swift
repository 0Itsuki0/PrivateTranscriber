//
//  ConfigureHotkeyView.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/07/01.
//

import SwiftUI


private struct ModifierAction {
    var flags: NSEvent.ModifierFlags
    var isInsert: Bool
}

struct ConfigureHotkeyView: View {

    var currentConfiguration: HotkeyConfiguration
    var onConfigurationChange: (HotkeyConfiguration) -> Void
    var onConfigurationStart: () -> Void
    var onConfigurationFinish: () -> Void

    @State private var userInputEnabled: Bool = false
    @State private var errorMessage: String? = nil

    @State private var eventMonitor: Any? = nil

    @Environment(\.dismiss) private var dismiss

    
    @State private var modifierActions: [ModifierAction] = []
    // when invalid combination detected, use this value to make sure not setting modifier flags when they are released
    @State private var pendingReleaseModifiers: NSEvent.ModifierFlags? = nil

    var body: some View {

        HStack {
            Group {
                if self.userInputEnabled {
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    } else {
                        Text("Press new key…")
                    }
                } else {
                    HotkeyView(
                        hotkey: currentConfiguration,
                    )
                }

            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(
                action: {
                    self.userInputEnabled.toggle()
                },
                label: {
                    Image(
                        systemName: self.userInputEnabled
                            ? "xmark" : "pencil"
                    )
                    .resizable().scaledToFit()
                    .frame(width: self.userInputEnabled ? 8 : 12, height: 12)
                    .fontWeight(self.userInputEnabled ? .regular : .heavy)
                    .padding(2)
                    .contentShape(Rectangle())
                }
            )
            .buttonStyle(.plain)
        }
        .focusable()
        .focusEffectDisabled()
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.primary.opacity(0.1), lineWidth: 1.0)
        )
        .frame(width: 200, height: 36)
        .onChange(
            of: userInputEnabled,
            initial: true
        ) {
            if self.userInputEnabled {
                self.onConfigurationStart()
                self.setupEventMonitor()
            } else {
                if let eventMonitor = self.eventMonitor {
                    NSEvent.removeMonitor(eventMonitor)
                }
                self.eventMonitor = nil
                self.onConfigurationFinish()
            }
        }
    }

    private func setupEventMonitor() {
        self.eventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyUp, .keyDown, .flagsChanged],
            handler: { event in
                if event.type == .flagsChanged {
                    return self.handleFlagChangeEvent(event)
                }

                return self.handleKeyupEvent(event)
            }
        )
    }

    private func handleKeyupEvent(_ event: NSEvent) -> NSEvent? {
        self.errorMessage = nil
        let modifiers = event.modifierFlags.intersection(
            .deviceIndependentFlagsMask
        ).validModifiers

        if modifiers.isEmpty {
            self.errorMessage = "invalid modifiers"
            return event
        }

        let newConfiguration = HotkeyConfiguration(
            modifierFlags: event.modifierFlags
                .intersection(.deviceIndependentFlagsMask)
                .validModifiers,
            key: event.keyCode,
            keyChar: HotkeyConfiguration.keyCodeStringMap[Int(event.keyCode)]
                ?? event.charactersIgnoringModifiers
        )
        onConfigurationChange(newConfiguration)
        self.userInputEnabled = false
        // return nil to consume the event
        return nil
    }
    
    
    private func handleFlagChangeEvent(_ event: NSEvent) -> NSEvent? {
        let modifierFlags = event.modifierFlags
            .intersection(.deviceIndependentFlagsMask)
            .validModifiers

        // check if the last removed modifier and whether if it is a pending released modifier
        if self.pendingReleaseModifiers != nil {
            self.pendingReleaseModifiers =
                modifierFlags.isEmpty ? nil : modifierFlags
            return nil
        }

        if let current = self.modifierActions.last?
            .flags, current != modifierFlags
        {

            self.modifierActions.append(
                .init(
                    flags: modifierFlags,
                    isInsert:
                        modifierFlags.isSuperset(
                            of: current
                        )
                )
            )
        } else {
            self.modifierActions = [
                .init(
                    flags: modifierFlags,
                    isInsert: true
                )
            ]
        }

        // all modifiers are released, record it as a hotkey
        if !modifierFlags.isEmpty {
            return event
        }

        guard
            let lastInsert = self.modifierActions
                .last(where: { $0.isInsert })
        else {
            return event
        }

        
        let newConfiguration = HotkeyConfiguration(
            modifierFlags: lastInsert.flags,
            key: nil,
            keyChar: nil
        )
        onConfigurationChange(newConfiguration)
        self.userInputEnabled = false
        // return nil to consume the event
        return nil
    }
}

struct HotkeyView: View {
    var hotkey: HotkeyConfiguration

    private var strings: [String] {
        var strings = hotkey.modifierFlags.stringRepresentations
        if let keyString = hotkey.key_string,
            !keyString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            strings.append(keyString)
        }
        return strings
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(strings, id: \.self) { string in
                keyView(string)
            }
        }

    }

    @ViewBuilder
    private func keyView(_ key: String) -> some View {
        Text(key)
            .foregroundStyle(.background)
            .font(.system(size: 10))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(.primary.opacity(0.9))
                    .stroke(
                        .primary.opacity(0.2),
                        style: .init(lineWidth: 1)
                    )
            )
            .fixedSize()
    }
    
}
