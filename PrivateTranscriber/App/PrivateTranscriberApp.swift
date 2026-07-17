//
//  PrivateTranscriberApp.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/07/13.
//

import AVFoundation
import SwiftUI

@main
struct PrivateTranscriberApp: App {
    private let transcriptionManager: TranscriptionManager
    private let userSettings = UserSettings()

    init() {
        self.transcriptionManager = TranscriptionManager(
            hotkeyConfiguration: userSettings.hotKey,
            locales: userSettings.locales,
            prioritizedLocale: userSettings.prioritizedLocale,
            activationType: userSettings.activationType,
            formattingEnabled: userSettings.formattingEnabled,
            captureDevice: userSettings.selectedCaptureDevice
        )
    }

    var body: some Scene {
        MenuBarExtra(
            content: {
                AppMenuView(transcriptionManager: transcriptionManager)
                    .environment(self.userSettings)
            },
            label: {
                Image(systemName: "waveform.badge.microphone")
                    .task {
                        if (try? AccessibilityService
                            .checkAccessibilityPermission()) == nil
                            || AVAudioApplication.shared.recordPermission
                                != .granted
                        {
                            EnvironmentValues().openSettings()
                        }
                    }
            }
        )
        .menuBarExtraStyle(.window)

        Settings {
            NavigationStack {
                SettingsView(transcriptionManager: transcriptionManager)
                    .environment(self.userSettings)
            }
        }
        .windowResizability(.contentSize)
    }
}
