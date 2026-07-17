//
//  AudioRecorder.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/07/14.
//

import AVFoundation
import Foundation

actor AudioRecorder {

    var isRecording: Bool {
        recorder?.isRecording ?? false
    }

    private var recorder: AVAudioRecorder?

    func startRecording(to url: URL, sampleRate: Double, channelCount: Int)
        throws
    {
        if let recorder {
            recorder.stop()
            self.recorder = nil
        }

        let recorderSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: Int(channelCount),
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsBigEndianKey: false,
        ]

        let recorder = try AVAudioRecorder(url: url, settings: recorderSettings)
        recorder.prepareToRecord()
        recorder.record()
        self.recorder = recorder
    }

    func stopRecording() {
        guard recorder?.isRecording == true else {
            self.recorder = nil
            return
        }
        recorder?.stop()
        recorder = nil
    }
}
