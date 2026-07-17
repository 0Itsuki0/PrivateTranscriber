//
//  TranscriptionManager.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/07/16.
//

import AVFoundation
import SwiftUI

private let category = "TranscriptionManager"
private let logger = Logger.shared


@Observable
class TranscriptionManager {
    private(set) var lastTranscript: String?

    private var transcriptionState: TranscriptionState = .downloading

    private var activationType: TranscriptionActivationType

    private var formattingEnabled: Bool

    private var captureDevice: AVCaptureDevice?

    private var transcriber: TranscriberCoordinator?

    private var configuringHotkey: Bool = false

    private var overlayPanel: NSPanel?

    private var hotkeyListener: HotkeyListener
    
    private let formatter: Formatter

    private let circleHeight: CGFloat = 36
    private let errorPanelWidth: CGFloat = 160

    private var panelPosition: NSPoint {
        // Use the primary screen (the one anchored at (0, 0) — same one the
        // menu bar lives on) rather than NSScreen.main, which follows the
        // key window and would put the disc on different displays depending
        // on what the user has focused.
        let screen =
            NSScreen.screens.first(where: { $0.frame.origin == .zero })
            ?? NSScreen.main
            ?? NSScreen.screens.first
        guard let screen else { return NSPoint(x: 1200, y: 800) }
        let f = screen.visibleFrame
        return NSPoint(
            x: f.maxX - 24,
            y: f.maxY - 24,
        )
    }

    init(
        hotkeyConfiguration: HotkeyConfiguration,
        locales: [Locale],
        prioritizedLocale: Locale,
        activationType: TranscriptionActivationType,
        formattingEnabled: Bool,
        captureDevice: AVCaptureDevice?
    ) {
        self.activationType = activationType
        self.formattingEnabled = formattingEnabled
        self.captureDevice = captureDevice
        self.hotkeyListener = HotkeyListener(
            targetHotkeyConfiguration: hotkeyConfiguration
        )
        self.formatter = Formatter()
        
        self.hotkeyListener.onTargetHotkeyDown = self.handleHotkeyDetected

        self.startHotkeyMonitorIfPossible()

        self.setupTranscriber(locales, prioritized: prioritizedLocale)

        self.preWarmMic()
    }

    func onAccessibilityPermissionGranted() {
        self.startHotkeyMonitorIfPossible()
    }

    private func startHotkeyMonitorIfPossible() {
        do {
            try AccessibilityService.checkAccessibilityPermission()
            try self.hotkeyListener.startHotkeysMonitor()
        } catch {
            showPanel(error: error)
        }
    }

    func hotkeyConfigurationStart() {
        self.configuringHotkey = true
    }

    func hotkeyConfigurationFinish() {
        self.configuringHotkey = false
    }

    func hotkeyConfigurationUpdate(_ configuration: HotkeyConfiguration) {
        do {
            try AccessibilityService.checkAccessibilityPermission()
            try self.hotkeyListener.updateHotkey(
                newHotkeyConfiguration: configuration
            )
        } catch {
            showPanel(error: error)
        }
    }

    func activationTypeUpdate(_ activationType: TranscriptionActivationType) {
        self.activationType = activationType
    }

    func formattingEnabledUpdate(_ enabled: Bool) {
        self.formattingEnabled = enabled
    }

    func localeUpdate(_ locales: [Locale], prioritized: Locale) {
        self.setupTranscriber(locales, prioritized: prioritized)
    }

    private func setupTranscriber(_ locales: [Locale], prioritized: Locale) {
        self.transcriptionState = .downloading
        Task {
            defer {
                self.transcriptionState = .idle
            }
            do {
                self.transcriber = try await TranscriberCoordinator(
                    locales: locales,
                    prioritizedLocale: prioritized
                )
            } catch {
                showPanel(error: error)
            }
        }
    }

    private func showPanel(error: Error? = nil) {
        if let error, error.isCancellationError {
            return
        }
        self.closePanel()
        self.overlayPanel = NonInteractiveFloatingPanel(
            view: {
                TranscriptionIndicatorView(
                    transcriptionState: self.transcriptionState,
                    error: error,
                    errorPanelWidth: self.errorPanelWidth,
                    circleHeight: self.circleHeight,
                    dismissInSecond: 2,
                    dismiss: self.closePanel
                )
            },
            position: .init(
                x: self.panelPosition.x
                    - (error == nil ? circleHeight : errorPanelWidth),
                y: self.panelPosition.y
            )
        )

        // NOTE: cannot use NSApp.activate here
        // Reason: if we are calling NSApp.activate and we have other windows opened
        // the workspace will be switched
        Task { @MainActor in
            self.overlayPanel?.orderFrontRegardless()
        }
    }

    private func closePanel() {
        overlayPanel?.close()
        self.overlayPanel = nil
    }

    func handleHotkeyDetected(_ isDown: Bool) {
        guard !self.configuringHotkey else { return }
        switch self.activationType {
        case .hold:
            isDown
                ? startTranscription() : finishTranscription()
        case .tap:
            guard isDown else { return }
            self.transcriptionState == .recording
                ? finishTranscription() : startTranscription()
        }
    }

    private func startTranscription() {
        guard let transcriber else {
            showPanel(error: TranscriberError.failToSetup)
            return
        }

        guard
            let captureDevice = self.captureDevice
                ?? InputDeviceManager.defaultDevice
        else {
            showPanel(error: RecordingError.micNotFound)
            return
        }

        guard AVAudioApplication.shared.recordPermission == .granted else {
            showPanel(error: RecordingError.permissionDenied)
            return
        }

        guard
            self.transcriptionState == .idle
        else {
            if self.transcriptionState == .downloading {
                showPanel()
            }
            return
        }

        // update at the beginning to prevent consecutive calls start recording twice
        self.transcriptionState = .recording
        logger.info(category: category, message: "\(#function)")

        Task { [weak self] in
            do {
                try await transcriber.startRecording(
                    with: captureDevice,
                    onSessionError: { error in
                        Task { @MainActor in
                            self?.showPanel(error: error)
                        }
                    }
                )
                self?.showPanel()
            } catch (let error) {
                Task { @MainActor in
                    self?.transcriptionState = .idle
                    self?.showPanel(error: error)
                }
            }
        }
    }

    private func finishTranscription() {
        guard let transcriber else {
            return
        }

        guard self.transcriptionState == .recording else {
            return
        }

        self.closePanel()
        logger.info(category: category, message: "\(#function)")
        let start = Date()
        Task {
            defer {
                self.transcriptionState = .idle
            }
            do {
                self.transcriptionState = .processing
                // this part is suppose to be instantaneous, so no need to show the processing overlay
                var transcription = try await transcriber.stopRecording()
                guard
                    !transcription.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                else {
                    logger.info(
                        category: category,
                        message: "Empty transcription"
                    )
                    return
                }
                logger.info(
                    category: category,
                    message:
                        """
                        transcription before format: \(transcription),
                        latency: \(abs(start.timeIntervalSinceNow).formatted(.number.precision(.fractionLength(2)))) sec
                        """
                )

                var errored: Bool = false
                if formattingEnabled {
                    do {
                        showPanel()
                        transcription = try await self.formatter.format(
                            transcription
                        )
                        logger.info(
                            category: category,
                            message:
                                """
                                transcription after format: \(transcription),
                                latency: \(abs(start.timeIntervalSinceNow).formatted(.number.precision(.fractionLength(2)))) sec
                                """
                        )
                    } catch (let error) {
                        // show error panel but insert the unformatted tex
                        showPanel(error: error)
                        errored = true
                    }
                }
                try TextInserter.insertText(transcription)
                self.lastTranscript = transcription
                if !errored { closePanel() }
            } catch (let error) {
                showPanel(error: error)
            }
        }
    }

    private func preWarmMic() {
        DispatchQueue.global(qos: .utility).async {
            var desc = AudioComponentDescription(
                componentType: kAudioUnitType_Output,
                componentSubType: kAudioUnitSubType_HALOutput,
                componentManufacturer: kAudioUnitManufacturer_Apple,
                componentFlags: 0,
                componentFlagsMask: 0
            )
            _ = AudioComponentFindNext(nil, &desc)

            _ = InputDeviceManager.availableDevices
            _ = InputDeviceManager.defaultDevice
        }
    }
}
