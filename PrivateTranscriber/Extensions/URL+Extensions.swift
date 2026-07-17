//
//  URL+Extensions.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/05/10.
//

import Foundation
import UniformTypeIdentifiers

nonisolated extension URL {
    var absolutePath: String {
        return self.path(percentEncoded: false)
    }

    var parentDirectory: URL {
        return self.appending(component: "..").standardized
    }

    var isDirectory: Bool {
        (try? self.resourceValues(forKeys: [.isDirectoryKey]).isDirectory)
            ?? false
    }

    var fileName: String {
        return self.lastPathComponent
    }

    var createdAt: Date {
        (try? self.resourceValues(forKeys: [.creationDateKey]))?
            .creationDate ?? Date.distantPast
    }

    var isTemp: Bool {
        return self.absoluteURL.absoluteString.starts(
            with: URL.temporaryDirectory.absoluteString
        )
    }

    var fileNameWithoutExtension: String {
        return self.deletingPathExtension().lastPathComponent
    }

    static let imageDirectory: URL = URL.temporaryDirectory
        .appendingPathComponent("Images")
}
