//
//  HotkeyListener.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/05/10.
//

import Cocoa
import Foundation

nonisolated private let category = "HotkeyListener"
nonisolated private let logger = Logger.shared

enum HotkeyError: Error, LocalizedError {
    case failedToCreateEventTap

    var errorDescription: String? {
        switch self {
        case .failedToCreateEventTap:
            "Failed to create hotkey listener."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .failedToCreateEventTap:
            nil
        }
    }
}

nonisolated final class HotkeyListener: @unchecked Sendable {

    var onTargetHotkeyDown: ((_ isDown: Bool) -> Void)?

    private var targetHotkeyConfiguration: HotkeyConfiguration

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(
        targetHotkeyConfiguration: HotkeyConfiguration,
    ) {
        self.targetHotkeyConfiguration = targetHotkeyConfiguration
    }

    deinit {
        self.removeHotkeyMonitor()
    }

    func updateHotkey(
        newHotkeyConfiguration: HotkeyConfiguration
    ) throws {
        self.removeHotkeyMonitor()
        self.targetHotkeyConfiguration = newHotkeyConfiguration
        try self.startHotkeysMonitor()
    }

    func startHotkeysMonitor() throws {
        logger.info(category: category, message: "Start hotkey monitoring")
        self.removeHotkeyMonitor()

        // CGEventType: https://developer.apple.com/documentation/coregraphics/cgeventtype
        // CGEventType: https://developer.apple.com/documentation/coregraphics/cgeventtype
        let eventMask =
            self.targetHotkeyConfiguration.key == nil
            ? CGEventMask(1 << CGEventType.flagsChanged.rawValue)
            : CGEventMask(
                (1 << CGEventType.keyDown.rawValue)
                    | (1 << CGEventType.keyUp.rawValue)
            )

        let callback: CGEventTapCallBack = { (proxy, type, event, me) in
            guard let manager = me else {
                return nil
            }
            let wrapper = Unmanaged<HotkeyListener>.fromOpaque(manager)
                .takeUnretainedValue()
            return wrapper.handleEvent(
                proxy: proxy,
                type: type,
                event: event,
                userInfo: manager
            )
        }

        guard
            let eventTap: CFMachPort = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                // `listenOnly` only instead of `defaultTap` so that the app can be sandboxed.
                // However, in this case, the app won't be able to consume the event,
                // ie: return nil from handleEvent will still have the event penetrate up to other apps
                options: .defaultTap,
                eventsOfInterest: eventMask,
                callback: callback,
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            )
        else {
            throw HotkeyError.failedToCreateEventTap
        }

        self.eventTap = eventTap

        // Creates a CFRunLoopSource object for a CFMachPort object.
        // https://developer.apple.com/documentation/CoreFoundation/CFMachPortCreateRunLoopSource(_:_:_:)
        let runLoopSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault,
            eventTap,
            0
        )
        self.runLoopSource = runLoopSource
        // add the source to a run loop
        // https://developer.apple.com/documentation/corefoundation/cfrunloopaddsource(_:_:_:)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

        // Event taps are normally enabled when created. If an event tap becomes unresponsive, or if a user requests that event taps be disabled, then a kCGEventTapDisabled event is passed to the event tap callback function. Event taps may be re-enabled by calling this function.
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    func removeHotkeyMonitor() {
        guard let eventTap = self.eventTap else { return }

        // Disable the tap first to stop receiving events
        CGEvent.tapEnable(tap: eventTap, enable: false)

        if let runLoopSource = self.runLoopSource {
            CFRunLoopRemoveSource(
                CFRunLoopGetCurrent(),
                runLoopSource,
                .commonModes
            )
            self.runLoopSource = nil
        }

        // Invalidate the Mach port to fully clean up the event tap
        CFMachPortInvalidate(eventTap)
        self.eventTap = nil
    }

    // Returning
    // - cgEvent: to allow it to continue to the active app
    // - nil: consume the event
    private func handleEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent,
        userInfo: UnsafeMutableRawPointer?
    ) -> Unmanaged<CGEvent>? {
        // Must handle these before NSEvent(cgEvent:) — they throw ObjC exceptions
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            // Re-enable tap if still active (e.g., re-enable after timeout)
            if let tap = self.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard let nsEvent = NSEvent(cgEvent: event) else {
            return Unmanaged.passUnretained(event)
        }

        guard type == CGEventType.keyDown || type == CGEventType.flagsChanged
        else {
            // key up event trigger release (stop recording) so we don't need to do additional handling for it
            self.onTargetHotkeyDown?(false)
            return Unmanaged.passUnretained(event)
        }

        let isTarget =
            type == CGEventType.keyDown
            ? self.targetHotkeyConfiguration.isTargetKeydown(nsEvent)
            : self.targetHotkeyConfiguration.isTargetFlagChange(nsEvent)

        self.onTargetHotkeyDown?(isTarget)

        // consume the event if it is a target regardless of whether it is a repeat or not
        return isTarget ? nil : Unmanaged.passUnretained(event)
    }
}
