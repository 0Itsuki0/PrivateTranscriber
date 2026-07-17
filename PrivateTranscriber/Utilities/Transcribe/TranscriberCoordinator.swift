//
//  ContentView.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/07/13.
//

import AVFAudio
import Speech
import SwiftUI

nonisolated private let category = "TranscriberCoordinator"
nonisolated private let logger = Logger.shared

nonisolated class TranscriberCoordinator {

    private let languageDetector: LanguageDetector

    private var captureSession: IsolatedCaptureSession?
    private var audioSequence:
        (any AsyncSequence<AnalyzerInput, any Error> & Sendable)?
    private var transcribers: [Transcriber] = []
    private var analyzer: SpeechAnalyzer

    private var recordingTask: Task<Void, Never>?

    private var lastAudioTime: CMTime?

    init(locales: [Locale], prioritizedLocale: Locale) async throws {
        self.transcribers = locales.map({ locale in
            return Transcriber(locale: locale)
        })
        self.analyzer = SpeechAnalyzer(modules: transcribers.map(\.transcriber))
        self.languageDetector = try await LanguageDetector(
            possibleLocales: locales,
            prioritizedLocale: prioritizedLocale
        )

        try await withThrowingTaskGroup(of: Void.self) { group in
            for transcriber in transcribers {
                group.addTask {
                    try await transcriber.downloadAssetsIfNeeded()
                }
            }
            try await group.waitForAll()
        }
    }

    func startRecording(
        with device: AVCaptureDevice,
        onSessionError: @escaping @Sendable (Error) -> Void
    ) async throws {
        guard await self.captureSession?.isRunning != true else {
            return
        }
        self.lastAudioTime = nil

        let provider =
            try await CaptureInputSequenceProvider.providerWithSession(
                from: device,
                compatibleWith: transcribers.map(\.transcriber)
            )

        captureSession = IsolatedCaptureSession(provider.captureSession)
        audioSequence = provider.analyzerInputs

        recordingTask = Task {
            // This is not expected to return until recordingTask is cancelled.
            await runSession(onSessionError: onSessionError)

            // Clean up
            recordingTask = nil
            self.captureSession = nil
        }
    }

    func stopRecording() async throws -> String {
        // Causes runSession to finish up and return
        recordingTask?.cancel()

        do {
            try await withThrowingTaskGroup(of: Void.self) {
                [weak self] group in
                guard let self else {
                    return
                }
                // Task 1: finalize transcription
                group.addTask {
                    // Wait for max of 1 second. it shouldn't take longer than this
                    let maxWait = 1.0 * 1000
                    var timeElapsed: TimeInterval = 0
                    var resolved = false
                    while self.lastAudioTime == nil {
                        try? await Task.sleep(for: .milliseconds(1))
                        timeElapsed += 1
                        if let lastAudioTime = self.lastAudioTime {
                            try await self.analyzer.finalizeAndFinish(
                                through: lastAudioTime
                            )
                            resolved = true
                            break
                        }
                        if timeElapsed > maxWait {
                            break
                        }
                    }
                    if !resolved {
                        // audio time comes in before the task even started
                        if let lastAudioTime = self.lastAudioTime {
                            try await self.analyzer.finalizeAndFinish(
                                through: lastAudioTime
                            )
                        } else {
                            try await self.analyzer.finalize(through: nil)
                        }
                    }
                }

                // stop LID if not yet and get a language detection result
                group.addTask {
                    try await self.languageDetector.stopLanguageDetection()
                }

                try await group.waitForAll()
            }
        } catch (let error) {
            guard error is CancellationError else {
                throw error
            }
        }

        let language = languageDetector.language

        guard
            let targetTranscriber = self.transcribers.first(where: {
                $0.locale.language.languageCode?.identifier == language
                    || $0.locale.language.minimalIdentifier.starts(
                        with: language
                    )
            }) ?? self.transcribers.first(where: { !$0.isTranscriptEmpty })
                ?? self.transcribers.first
        else {
            throw TranscriberError.targetTranscriberNotFound
        }

        // recreate after retrieving the target transcriber
        // required after calling any finish method on the analyzer
        self.recreateTranscriberAnalyzer()

        return targetTranscriber.transcript
    }

    private func runSession(onSessionError: @escaping @Sendable (Error) -> Void)
        async
    {
        do {
            // Use task group for structured concurrency
            try await withThrowingDiscardingTaskGroup { group in
                // Subtask 1: language detection
                group.addTask {
                    do {
                        try await self.languageDetector.startLanguageDetection()
                    } catch (let error) {
                        // NOT throwing here as the language is a bonus, not a requirement
                        logger.error(
                            category: category,
                            message:
                                "Error starting language detection: \(error)"
                        )
                    }
                }

                // Subtask 1: Analyze audio from the capture session
                group.addTask {
                    try await self.captureAndAnalyzeAudio()
                }

                // Subtask 3: transcription updates from the transcriber module
                for transcriber in transcribers {
                    group.addTask {
                        // This cancellation shield prevents the transcription update loop from immediately ending
                        // when the `stopRecording()` method cancels the recording task.
                        try await withTaskCancellationShield {
                            try await transcriber.updateTranscript()
                        }
                    }
                }
            }
        } catch {
            if !error.isCancellationError {
                onSessionError(error)
            }
            await captureSession?.stopRunning()
            try? await languageDetector.stopLanguageDetection()
            self.recreateTranscriberAnalyzer()
        }
    }

    @concurrent
    private func captureAndAnalyzeAudio() async throws {
        guard let captureSession = captureSession,
            let audioSequence = audioSequence
        else {
            return
        }
        if await captureSession.startRunning() {
            logger.info(category: category, message: "capture is running")

            // Returns when task is canceled
            self.lastAudioTime = try await analyzer.analyzeSequence(
                audioSequence
            )

            await captureSession.stopRunning()
            logger.info(category: category, message: "capture stopped running")
        }
    }

    // required after calling any finish method on the analyzer
    private func recreateTranscriberAnalyzer() {
        self.captureSession = nil
        self.lastAudioTime = nil
        self.transcribers = self.transcribers.map(\.locale).map({ locale in
            return Transcriber(locale: locale)
        })
        self.analyzer = SpeechAnalyzer(modules: transcribers.map(\.transcriber))
    }
}
