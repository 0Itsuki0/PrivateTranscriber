//
//  IsolatedCaptureSession.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/07/15.
//

import AVFoundation

// MARK: AVCaptureSession thread safety
actor IsolatedCaptureSession {
    private let captureSession: AVCaptureSession

    init(_ captureSession: AVCaptureSession) {
        self.captureSession = captureSession
    }

    func startRunning() -> Bool {
        captureSession.startRunning()
        return captureSession.isRunning
    }

    func stopRunning() {
        captureSession.stopRunning()
    }

    var isRunning: Bool {
        captureSession.isRunning
    }
}
