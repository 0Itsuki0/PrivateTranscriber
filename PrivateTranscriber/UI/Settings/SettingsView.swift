//
//  SettingsView.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/07/01.
//

import AVFoundation
import Combine
import Speech
import SwiftUI

struct SettingsView: View {
    @Environment(UserSettings.self) private var userSettings
    var transcriptionManager: TranscriptionManager

    @State private var hotkeyPermission: Bool = false

    @State private var micPermission: AVAudioApplication.recordPermission =
        .undetermined

    @Environment(\.openURL) private var openURL

    // for auto refresh
    @State private var cancellable: Cancellable?
    @State private var timer = Timer.publish(every: 0.2, on: .main, in: .common)

    var body: some View {
        @Bindable var userSettings = userSettings

        Form {
            Section("Hotkey") {

                HStack {
                    Text("Combination")
                    ConfigureHotkeyView(
                        currentConfiguration: userSettings.hotKey,
                        onConfigurationChange: {
                            userSettings.hotKey = $0
                            transcriptionManager.hotkeyConfigurationUpdate($0)
                        },
                        onConfigurationStart: transcriptionManager
                            .hotkeyConfigurationStart,
                        onConfigurationFinish: transcriptionManager
                            .hotkeyConfigurationFinish
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Picker(
                    selection: $userSettings.activationType,
                    content: {
                        ForEach(TranscriptionActivationType.allCases) { type in
                            Text(type.title)
                                .tag(type)
                        }
                    },
                    label: {
                        Text("Activation Type")
                    },
                    currentValueLabel: {
                        Text(userSettings.activationType.title)
                    }
                )
                .onChange(of: userSettings.activationType) {
                    self.transcriptionManager.activationTypeUpdate(
                        userSettings.activationType
                    )
                }

                HStack {
                    Text("Permission")

                    Group {
                        if self.hotkeyPermission {
                            Text("Granted")
                                .foregroundStyle(.secondary)
                        } else {
                            Button(
                                action: {
                                    AccessibilityService
                                        .requestAccessibilityPermission()
                                },
                                label: {
                                    Text("Grant Permission")
                                }
                            )

                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

            }

            Section {

                // TODO: - add input selection (Future)

                HStack {
                    Text("Permission")

                    Group {
                        switch self.micPermission {
                        case .undetermined:
                            Button(
                                action: {
                                    Task {
                                        await AVAudioApplication
                                            .requestRecordPermission()
                                    }
                                },
                                label: {

                                }
                            )
                        case .denied:
                            Button(
                                action: {
                                    if let settingURL = URL(
                                        string:
                                            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Microphone"
                                    ) {
                                        self.openURL(settingURL)
                                    }
                                },
                                label: {

                                }
                            )
                        case .granted:
                            Text("Granted")
                                .foregroundStyle(.secondary)
                        default:
                            Button(
                                action: {
                                    AccessibilityService
                                        .requestAccessibilityPermission()
                                },
                                label: {
                                    Text("Grant Permission")
                                }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            } header: {
                Text("Audio Input")
                    .padding(.top, 8)
            }

            Section {
                Toggle(
                    isOn: $userSettings.formattingEnabled,
                    label: {
                        Text("Formatting")
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

                NavigationLink(
                    destination: {
                        TranscriptionLocaleSelectionView(
                            saveLocales: {
                                userSettings.locales = $0
                                transcriptionManager.localeUpdate(
                                    userSettings.locales,
                                    prioritized: userSettings.prioritizedLocale
                                )
                            },
                            selectedLocale: userSettings.locales
                        )
                    },
                    label: {
                        VStack(alignment: .leading) {
                            Text("Languages")
                            Text(
                                userSettings.locales.map(
                                    \.identifier
                                ).joined(separator: ", ")
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                )

            } header: {
                Text("Transcription")
                    .padding(.top, 8)
            }
        }
        .formStyle(.grouped)
        .scrollBounceBehavior(.basedOnSize)
        .overlay(alignment: .bottomTrailing) {
            HStack {
                if let appVersion {
                    Text("v\(appVersion)")
                }
            }
            .padding(.all, 24)

        }
        .frame(width: 600, height: 480)
        .onReceive(timer) { _ in
            self.refreshPermissionStates()
        }
        .onAppear {
            if self.micPermission != .granted || self.hotkeyPermission == false
            {
                self.cancellable = self.timer.connect()
            }
            self.refreshPermissionStates()
        }
        .onDisappear {
            self.cancellable?.cancel()
        }
        .onWindow { window in
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(10))
                window.orderFrontRegardless()
                window.makeKey()
            }
        }
        .onChange(of: self.hotkeyPermission) {
            if hotkeyPermission {
                transcriptionManager.onAccessibilityPermissionGranted()
            }
        }
    }

    private func refreshPermissionStates() {
        do {
            try AccessibilityService.checkAccessibilityPermission()
            self.hotkeyPermission = true
        } catch (_) {
            self.hotkeyPermission = false
        }
        self.micPermission = AVAudioApplication.shared.recordPermission
    }

}

private struct TranscriptionLocaleSelectionView: View {
    var saveLocales: ([Locale]) -> Void
    @State var selectedLocale: [Locale]

    @State private var localesAvailable: [Locale] = []
    @State private var searchQuery: String = ""
    @Environment(\.dismiss) private var dismiss

    private var filteredLocales: [Locale] {
        let trimmed = searchQuery.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if trimmed.isEmpty {
            return self.localesAvailable
        }
        return self.localesAvailable.filter({
            $0.identifier.localizedCaseInsensitiveContains(self.searchQuery)
        })
    }
    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("", text: $searchQuery)
                        .listRowBackground(Color.clear)
                        .multilineTextAlignment(.leading)
                }
            }

            Section {
                ForEach(filteredLocales, id: \.identifier) { locale in
                    let selected = selectedLocale.contains(locale)

                    Button(
                        action: {
                            if selected {
                                selectedLocale.removeAll(where: { $0 == locale }
                                )
                            } else {
                                if !selectedLocale.contains(locale) {
                                    selectedLocale.append(locale)
                                }
                            }
                        },
                        label: {
                            HStack {
                                Text(locale.identifier)
                                    .frame(
                                        maxWidth: .infinity,
                                        alignment: .leading
                                    )

                                Image(
                                    systemName: selected
                                        ? "checkmark.circle" : "circle"
                                )
                                .foregroundStyle(selected ? .blue : .primary)
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                    )
                    .buttonSizing(.flexible)
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Selected locales")

                Text(
                    self.selectedLocale.isEmpty
                        ? "(none)"
                        : self.selectedLocale.map(\.identifier).joined(
                            separator: ", "
                        )
                )
                .font(.subheadline)
            }
        }
        .formStyle(.grouped)
        .scrollBounceBehavior(.basedOnSize)
        .padding(.bottom, 36)
        .navigationTitle("Transcription Languages")
        .navigationBarBackButtonHidden()
        .safeAreaInset(edge: .top) {
            HStack(spacing: 8) {
                Button(
                    action: {
                        self.dismiss()
                    },
                    label: {
                        Image(systemName: "chevron.left")
                    }
                )
                Spacer()
                Button(
                    action: {
                        self.saveLocales(selectedLocale)
                        dismiss()
                    },
                    label: {
                        Text("Save")
                    }
                )
                .buttonStyle(.glassProminent)
                .disabled(selectedLocale.isEmpty)
            }
            .padding(.horizontal, 24)

        }
        .task {
            self.localesAvailable = await DictationTranscriber.supportedLocales
        }
        .frame(width: 600, height: 480)
    }
}

let appVersion =
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
