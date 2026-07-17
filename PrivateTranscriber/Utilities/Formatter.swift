//
//  Formatter.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/07/14.
//

import Foundation
import FoundationModels

//private let modelConfiguration = LLMRegistry.gpt_oss_20b_MXFP4_Q8

//let gpt_oss_20b_MXFP4_Q8 = ModelConfiguration(
//    id: "mlx-community/gpt-oss-20b-MXFP4-Q8",
//    defaultPrompt: "Why is the sky blue?"
//)

nonisolated
class Formatter {
    private let model = SystemLanguageModel.default
    
    private var session: LanguageModelSession
    
    init() {
        self.session = LanguageModelSession(
            model: self.model,
            instructions: compactPrompt
        )
        session.prewarm()
    }
    
    private func resetSession() {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            self.session = LanguageModelSession(
                model: self.model,
                instructions: compactPrompt
            )
            session.prewarm()
        }
    }
    
    func format(_ text: String) async throws -> String {
        guard self.model.availability == .available else {
            throw FormatterError.modelNotAvailable
        }
        let response = try await session.respond(to: text)
        self.resetSession()
        return response.content
    }
}
