//
//  WindowTracker.swift
//  HandleWindow
//
//  Created by Philipp on 21.10.22.
//

import SwiftUI

private struct WindowStateEnvironmentKey: EnvironmentKey {
    static var defaultValue = WindowState()
}

extension EnvironmentValues {
    var window: WindowState {
        get { self[WindowStateEnvironmentKey.self] }
        set { self[WindowStateEnvironmentKey.self] = newValue }
    }
}

/// This view modifier is holding and initialising `WindowState`, installs the `WindowAccessor` view in the views background to track the window and
/// publishes state changes to the environment as `\.window` key.
struct WindowTracker: ViewModifier {

    @State private var state = WindowState()

    let onConnect: ((WindowState, Bool) -> Void)?
    let onVisibilityChange: ((NSWindow, Bool) -> Void)?

    func body(content: Content) -> some View {
        print(Self.self, #function, state)
        return content
            .background(
                WindowAccessor(onConnect: connectToWindow, onDisconnect: disconnectFromWindow)
            )
            .environment(\.window, state)
    }

    private func connectToWindow(_ window: NSWindow, _ monitor: WindowMonitor) {
        state = WindowState(monitor: monitor, underlyingWindow: window)
        onConnect?(state, true)

        // Setup visibility tracking
        monitor.observeWindowAttribute(for: \.isVisible, options: .new, using: { (window, isVisible) -> Void in
            state.isVisible = isVisible
            onVisibilityChange?(window, isVisible)
        })
    }

    private func disconnectFromWindow() {
        onConnect?(state, false)
        state = WindowState()
    }
}

extension View {
    func trackUnderlyingWindow(onConnect: ((WindowState, Bool) -> Void)? = nil, onVisibilityChange: ((NSWindow, Bool) -> Void)? = nil) -> some View {
        return self.modifier(WindowTracker(onConnect: onConnect, onVisibilityChange: onVisibilityChange))
    }
}
