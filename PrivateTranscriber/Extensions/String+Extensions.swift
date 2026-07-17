//
//  String.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/05/10.

import Foundation

nonisolated extension String {

    var data: Data {
        return Data(self.utf8)
    }
}
