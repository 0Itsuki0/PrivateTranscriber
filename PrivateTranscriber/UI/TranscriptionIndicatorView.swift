//
//  TranscriptionIndicatorView.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/07/17.
//

import SwiftUI

// overlay panel at the top right of the screen
struct TranscriptionIndicatorView: View {
    var transcriptionState: TranscriptionState
    var error: Error?
    var errorPanelWidth: CGFloat
    var circleHeight: CGFloat
    var dismissInSecond: TimeInterval
    var dismiss: () -> Void

    var body: some View {
        Group {
            if let error {
                Text(error.localizedDescription)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8).stroke(.red)
                            .glassEffect(
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                    )
                    .frame(width: errorPanelWidth)
            } else {
                Circle()
                    .fill(.clear)
                    .stroke(.gray)
                    .glassEffect()
                    .frame(width: circleHeight, height: circleHeight)
                    .overlay {
                        switch transcriptionState {
                        case .downloading:
                            Image(systemName: "arrow.down.to.line.compact")
                                .symbolEffect(.pulse, isActive: true)
                        case .idle:
                            EmptyView()
                        case .recording:
                            Image(systemName: "microphone.fill")
                                .symbolEffect(.pulse, isActive: true)
                        case .processing:
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
            }
        }
        .padding(.all, 2)
        .task {
            do {
                try await Task.sleep(for: .seconds(self.dismissInSecond))
                self.dismiss()
            } catch {
                self.dismiss()
            }
        }

    }
}
