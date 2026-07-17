//
//  InputDeviceManager.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/01/27.
//

import AVFoundation
import CoreAudio
import SwiftUI

nonisolated private let category = "InputDeviceManager"
nonisolated private let logger = Logger.shared

nonisolated enum InputDeviceManager {

    static var availableDevices: [AVCaptureDevice] {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .microphone, .external,
        ]

        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .audio,
            position: .unspecified
        )

        let microphones = session.devices
        return microphones.filter({
            $0.transportType != kAudioDeviceTransportTypeAggregate
                && $0.transportType != kAudioDeviceTransportTypeVirtual
                && $0.isConnected
        }).sorted(by: { first, second in
            if first.isBuiltIn {
                return true
            }
            if second.isBuiltIn {
                return false
            }
            return first.localizedName < second.localizedName
        })
    }

    static var defaultDevice: AVCaptureDevice? {
        AVCaptureDevice.default(
            .microphone,
            for: .audio,
            position: .unspecified
        )
    }
}
