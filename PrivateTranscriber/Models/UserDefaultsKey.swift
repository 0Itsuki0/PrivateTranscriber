//
//  UserDefaultsKey.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/06/23.
//

import Foundation

enum UserDefaultsKey: String, CaseIterable {
        
    case hotkey
    
    case locales
    
    case prioritizedLocale
    
    case activationType
    
    case formattingEnabled
    
    case captureDevicePreference

    static let userDefaults = UserDefaults.standard

    var key: String {
        return "private_transcriber_\(self.rawValue.lowercased())"
    }

    func setValue(value: Any?) {
        Self.userDefaults.setValue(value, forKey: self.key)
    }

    func getValue() -> Any? {
        return Self.userDefaults.object(forKey: self.key)
    }
}
