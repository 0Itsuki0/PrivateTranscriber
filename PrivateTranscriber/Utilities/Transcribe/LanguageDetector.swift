//
//  LanguageDetector.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/07/17.
//

import Foundation
import MLXAudioCore
import MLXAudioLID

nonisolated private let category = "LanguageDetector"
nonisolated private let logger = Logger.shared

nonisolated class LanguageDetector {
    private static let lidSampleRate: Int = 16000
    private static let lidChannelCount: Int = 1

    var language: String {
        self._detectedLanguage ?? prioritizedLocale.language.languageCode?
            .identifier ?? prioritizedLocale.language.minimalIdentifier
    }
    private var _detectedLanguage: String?

    private let languageDetector: EcapaTdnn
    private let recorder: AudioRecorder
    private let url = URL.temporaryDirectory.appending(path: "lang.wav")

    private let prioritizedLocale: Locale
    private let possibleLocales: [Locale]

    init(
        possibleLocales: [Locale],
        prioritizedLocale: Locale
    ) async throws {
        self.prioritizedLocale = prioritizedLocale
        self.possibleLocales = possibleLocales
        self.languageDetector = try await EcapaTdnn.fromPretrained(
            "beshkenadze/lang-id-voxlingua107-ecapa-mlx"
        )
        self.recorder = AudioRecorder()
    }

    func startLanguageDetection() async throws {
        try? FileManager.default.removeItem(at: url)
        try await self.recorder.startRecording(
            to: url,
            sampleRate: Double(Self.lidSampleRate),
            channelCount: Self.lidChannelCount
        )
        // record for 5 seconds (or whatever length is the audio) of audio
        do {
            try await Task.sleep(for: .seconds(5))
        } catch (let error) {
            guard error is CancellationError else {
                throw error
            }
        }
        try await self.stopLanguageDetection()
    }

    func stopLanguageDetection() async throws {
        // detection finished before audio finish
        guard await self.recorder.isRecording else {
            return
        }
        // still running detection
        await self.recorder.stopRecording()
        let (_, audio) = try loadAudioArray(
            from: url,
            sampleRate: Self.lidSampleRate
        )
        let detection = self.languageDetector.predict(waveform: audio, topK: 1)
        logger.info(
            category: "LanguageDetector",
            message: "language detected: \(detection.language)"
        )

        var allLocales = Set(self.possibleLocales)
        allLocales.insert(self.prioritizedLocale)

        if allLocales.contains(where: {
            $0.language.minimalIdentifier.lowercased().contains(
                detection.language
            )
        }) {
            self._detectedLanguage = detection.language
        }
    }
}
