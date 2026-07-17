//
//  Transcriber.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/07/17.
//

import Speech

nonisolated class Transcriber {
    var isTranscriptEmpty: Bool {
        self.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private(set) var transcript: String = ""
    let transcriber: DictationTranscriber
    let locale: Locale

    private var pollingResult: Bool = false

    init(locale: Locale) {
        self.locale = locale
        self.transcriber = DictationTranscriber(
            locale: locale,
            preset: .progressiveShortDictation
        )
    }

    func downloadAssetsIfNeeded() async throws {
        if let installationRequest =
            try await AssetInventory.assetInstallationRequest(
                supporting: [transcriber])
        {
            try await installationRequest.downloadAndInstall()
        }
    }

    func updateTranscript() async throws {
        // try to call self.transcriber.results twice will result in crash
        // Coordinator sometimes (almost never) call this method twice accidentally
        guard !self.pollingResult else {
            return
        }
        self.pollingResult = true
        for try await transcript in self.transcriber.results {
            if transcript.isFinal {
                self.transcript += "\(String(transcript.text.characters))"
            }
        }
        self.pollingResult = false
    }
}
