//
//  WindowAccessor.swift
//  PrivateTranscriber
//
//  Created by Itsuki on 2026/06/30.
//

import SwiftUI

extension View {
    func onWindow(_ onWindow: @escaping (NSWindow) -> Void) -> some View {
        background(WindowAccessor(onWindow: onWindow))
    }
}

private struct WindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> WindowAccessorView {
        let view = WindowAccessorView(onWindow: onWindow)
        return view
    }

    func updateNSView(_ nsView: WindowAccessorView, context: Context) {}

    // Subclassing NSView to override viewDidMoveToWindow
    class WindowAccessorView: NSView {
        let onWindow: (NSWindow) -> Void

        init(onWindow: @escaping (NSWindow) -> Void) {
            self.onWindow = onWindow
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window = self.window else {
                return
            }
            self.onWindow(window)
        }
    }
}
