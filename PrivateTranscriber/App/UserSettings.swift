//
//  UserSettings.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/06/23.
//

import AVFoundation
import SwiftUI

enum CaptureDevicePreference: Codable {
    case dynamic
    case fixed(uniqueID: String)

    var uniqueID: String? {
        switch self {
        case .dynamic:
            return nil
        case .fixed(uniqueID: let id):
            return id
        }
    }

    var captureDevice: AVCaptureDevice? {
        switch self {
        case .dynamic:
            InputDeviceManager.defaultDevice
        case .fixed(let uniqueID):
            InputDeviceManager.availableDevices.first(where: {
                $0.uniqueID == uniqueID
            }) ?? InputDeviceManager.defaultDevice
        }
    }
}

@Observable
class UserSettings {

    var hotKey: HotkeyConfiguration {
        didSet {
            if let data = try? JSONEncoder().encode(self.hotKey) {
                UserDefaultsKey.hotkey.setValue(value: data)
            }
        }
    }

    var locales: [Locale] {
        didSet {
            UserDefaultsKey.locales.setValue(
                value: self.locales.map(\.identifier)
            )
        }
    }

    var prioritizedLocale: Locale {
        return locales.first ?? .enUS
    }

    var activationType: TranscriptionActivationType {
        didSet {
            UserDefaultsKey.activationType.setValue(
                value: self.activationType.rawValue
            )
        }
    }

    var formattingEnabled: Bool {
        didSet {
            UserDefaultsKey.formattingEnabled.setValue(
                value: self.formattingEnabled
            )
        }
    }

    var selectedCaptureDevice: AVCaptureDevice? {
        self.captureDevicePreference.captureDevice
    }

    var captureDevicePreference: CaptureDevicePreference {
        didSet {
            if let data = try? JSONEncoder().encode(
                self.captureDevicePreference
            ) {
                UserDefaultsKey.captureDevicePreference.setValue(value: data)
            }
        }
    }

    init() {
        if let data = UserDefaultsKey.hotkey.getValue() as? Data,
            let setting = try? JSONDecoder().decode(
                HotkeyConfiguration.self,
                from: data
            )
        {
            self.hotKey = setting
        } else {
            self.hotKey = .default
        }

        self.locales =
            (UserDefaultsKey.locales.getValue() as? [String])?.compactMap({
                Locale(identifier: $0)
            }) ?? [.enUS]

        let activationTypeString =
            UserDefaultsKey.activationType.getValue() as? String ?? ""
        self.activationType =
            TranscriptionActivationType(rawValue: activationTypeString) ?? .hold

        self.formattingEnabled =
            UserDefaultsKey.formattingEnabled.getValue() as? Bool ?? false

        if let data = UserDefaultsKey.captureDevicePreference.getValue()
            as? Data,
            let preference = try? JSONDecoder().decode(
                CaptureDevicePreference.self,
                from: data
            )
        {
            self.captureDevicePreference = preference
        } else {
            self.captureDevicePreference = .dynamic
        }
    }
}

extension Locale {
    static let enUS: Locale = .init(identifier: "en_US")
}
