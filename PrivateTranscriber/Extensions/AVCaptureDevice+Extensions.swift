//
//  AVCaptureDevice+Extensions.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/07/17.
//

import AVFoundation

nonisolated extension AVCaptureDevice {
    public static let builtInMicUniqueId = "BuiltInMicrophoneDevice"

    public var isBuiltIn: Bool {
        // self.transportType == kAudioDeviceTransportTypeBuiltIn won't work
        // Wired headphone w/ mic or Wired mic will still have a transportType of kAudioDeviceTransportTypeBuiltIn
        return self.uniqueID == Self.builtInMicUniqueId
    }

    public var isBluetooth: Bool {
        return self.transportType == kAudioDeviceTransportTypeBluetooth
    }
}
