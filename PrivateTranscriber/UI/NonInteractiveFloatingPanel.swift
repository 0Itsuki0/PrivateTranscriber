//
//  NonInteractiveFloatingPanel.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/06/23.
//

import SwiftUI

class NonInteractiveFloatingPanel<Content: View>: NSPanel {

    init(@ViewBuilder view: () -> Content, position: CGPoint) {
        let hostingView = NSHostingView(rootView: view())
        
        super.init(
            contentRect: NSRect(origin: position, size: hostingView.fittingSize),
            // nonactivatingPanel: so that when interacting with the panel, not switching to the work space that the app is activated in.
            // Borderless to allow full screen overlay
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        self.level = .screenSaver  // popUpMenu will also work
        
        // remove title and buttons
        self.styleMask.remove(.titled)
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true

        self.collectionBehavior = [
            .canJoinAllSpaces,
            .ignoresCycle,
            .stationary,
        ]

        self.becomesKeyOnlyIfNeeded = true
        self.isFloatingPanel = true
        self.hidesOnDeactivate = false

        // set it clear here so the configuration in UtilityWindowView will be reflected as it is
        self.backgroundColor = .clear

        self.isMovableByWindowBackground = false
        self.isMovable = false
        self.isRestorable = false

        self.ignoresMouseEvents = true
        self.hasShadow = false

        self.animationBehavior = .none

        // Assign the AppKit content view wrapper
        self.contentView = hostingView
    }
    
    // Never steal key/main focus — matches the previous borderless window.
    // A non-activating panel still receives mouse events without being key.
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

}
