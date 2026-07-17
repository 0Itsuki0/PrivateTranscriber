//
//  Logger.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/06/23.
//

import OSLog
import SwiftUI

nonisolated let subsystem =
    "\(Bundle.main.bundleIdentifier, default: "com.itsuki.PrivateTranscriber")"

nonisolated
    private let logger = os.Logger(
        subsystem: subsystem,
        category: "ApplicationLog"
    )

nonisolated
    enum LogLevel: String, Codable
{
    case info
    case error
}

nonisolated struct LogMessage: Codable {
    var time: String = Date().ISO8601Format()
    var level: LogLevel
    var category: String
    var message: String

    var jsonString: String? {
        let encoder = JSONEncoder()

        if let data = try? encoder.encode(self),
            let jsonString = String(data: data, encoding: .utf8)
        {
            return jsonString
        }
        return nil
    }

    static func fromJsonString(_ string: String) -> LogMessage? {
        let data = Data(string.utf8)
        let decoder = JSONDecoder()
        return try? decoder.decode(LogMessage.self, from: data)
    }
}

nonisolated extension Date {
    var fileSafeISO: String {
        return self.formatted(
            .iso8601.year().month().day().timeZone(separator: .omitted).time(
                includingFractionalSeconds: false
            ).timeSeparator(.omitted)
        )
    }
}

actor Logger {

    static let shared = Logger()

    nonisolated(unsafe) var allFiles: [URL] = []

    private static let directory: URL = URL.temporaryDirectory.appending(
        path: "Logs"
    )
    private static let fileExtension = "txt"
    let filePath: URL

    private let fileHandle: FileHandle?

    private init() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: Self.directory.path) {
            do {
                try fileManager.createDirectory(
                    at: Self.directory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                logger.error(
                    "Error creating directory: \(error.localizedDescription)"
                )
            }
        }

        let fileSafeISOString = Date().fileSafeISO

        self.filePath = Self.directory.appending(
            path: "\(fileSafeISOString).\(Self.fileExtension)"
        )
        if !fileManager.fileExists(atPath: filePath.path) {
            fileManager.createFile(atPath: filePath.path, contents: nil)
        }

        logger.info("Log file written to \(self.filePath)")
        do {
            self.fileHandle = try FileHandle(forWritingTo: self.filePath)
        } catch (let error) {
            logger.error("\(error.localizedDescription)")
            self.fileHandle = nil
        }

        Task {
            // when log file count is large, could eventually block and therefore spawn to Task
            self.cleanLogsAndInitialize()
        }
    }

    deinit {
        try? self.fileHandle?.close()
    }

    public nonisolated
        func info(category: String, message: String)
    {
        #if DEBUG
            print(message)
        #else
            logger.info(
                "\(category, privacy: .public): \(message, privacy: .public)"
            )
        #endif

        Task { @MainActor [weak self] in
            await self?.writeLog(
                category: category,
                message: message,
                level: .info
            )
        }
    }

    public nonisolated
        func error(category: String, error: Error)
    {
        let message = error.localizedDescription
        #if DEBUG
            print(message)
        #else
            logger.error(
                "\(category, privacy: .public): \(message, privacy: .public)"
            )
        #endif

        Task { @MainActor [weak self] in
            await self?.writeLog(
                category: category,
                message: message,
                level: .error
            )
        }
    }

    public nonisolated
        func error(category: String, message: String)
    {
        #if DEBUG
            print(message)
        #else
            logger.error(
                "\(category, privacy: .public): \(message, privacy: .public)"
            )
        #endif

        Task { @MainActor [weak self] in
            await self?.writeLog(
                category: category,
                message: message,
                level: .error
            )
        }
    }

    private func writeLog(
        category: String,
        message: String,
        level: LogLevel
    ) {
        let log: LogMessage = .init(
            level: level,
            category: category,
            message: message
        )
        var message: String = """
            "time": "\(Date().ISO8601Format())", "level": "\(level)", "category": "\(category)", "msg": "\(message)"
            """
        if let jsonString = log.jsonString {
            message = jsonString
        }
        message = message + "\n"

        if let fileHandle {
            fileHandle.seekToEndOfFile()
            fileHandle.write(message.data)
        } else {
            try? message.data.write(to: self.filePath, options: .atomicWrite)
        }
    }

    // remove log files > 30 days
    nonisolated private func cleanLogsAndInitialize() {
        var current = Self.allLogFiles
        let oldLogs = current.filter({
            abs($0.createdAt.timeIntervalSinceNow) > 30.0 * 24.0 * 60.0 * 60.0
        })
        let fileManager = FileManager.default
        for log in oldLogs {
            try? fileManager.removeItem(at: log)
        }
        current.removeAll(where: { oldLogs.contains($0) })
        self.allFiles = current
    }
}

extension Logger {
    static var allLogFiles: [URL] {
        let items =
            (try? FileManager.default.contentsOfDirectory(
                at: Self.directory,
                includingPropertiesForKeys: [
                    .creationDateKey, .isRegularFileKey,
                ],
                options: [.skipsHiddenFiles]
            )) ?? []

        return Array(Set(items)).filter({
            $0.pathExtension == Self.fileExtension
        }).filter {
            url in
            (try? url.resourceValues(forKeys: [.isRegularFileKey]))?
                .isRegularFile == true
        }
        .sorted { a, b in
            return a.createdAt > b.createdAt  // newest first
        }
    }
}
