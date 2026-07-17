//
//  AppMenuView.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/07/01.
//

import AVFoundation
import SwiftUI

struct AppMenuView: View {
    @Environment(UserSettings.self) private var userSettings
    var transcriptionManager: TranscriptionManager

    @Environment(\.openSettings) private var openSettings

    var body: some View {
        @Bindable var userSettings = userSettings
        VStack(alignment: .leading, spacing: 12) {
            if let lastTranscript = transcriptionManager.lastTranscript {
                Button(
                    action: {
                        let pasteboard = NSPasteboard.general
                        pasteboard.declareTypes([.string], owner: nil)
                        let _ = pasteboard.setString(
                            lastTranscript,
                            forType: .string
                        )
                    },
                    label: {
                        Label(
                            "Copy last transcript",
                            systemImage: "document.on.document"
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                )
            }

            Toggle(
                isOn: $userSettings.formattingEnabled,
                label: {
                    Text("Enabled Formatting")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
            )
            .controlSize(.small)
            .toggleStyle(.switch)
            .onChange(of: userSettings.formattingEnabled) {
                transcriptionManager.formattingEnabledUpdate(
                    userSettings.formattingEnabled
                )
            }

            Divider()

            Button(
                action: {
                    self.openSettings()
                },
                label: {
                    Label("Settings", systemImage: "gearshape")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
            )

            Divider()
            Button(
                action: {
                    NSApplication.shared.terminate(nil)
                },
                label: {
                    Label("Quit", systemImage: "power")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
            )

        }
        .buttonStyle(.plain)
        .buttonSizing(.flexible)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(width: 240)
    }

}
