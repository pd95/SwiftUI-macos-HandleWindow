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

    let onConnect: (WindowState, Bool) -> Void

    func body(content: Content) -> some View {
        print(Self.self, #function, state)
        return content
            .background(WindowAccessor(onConnect: connectToWindow, onWillClose: windowWillClose))
            .environment(\.window, state)
    }

    private func connectToWindow(_ window: NSWindow, _ monitor: WindowMonitor) {
        state = WindowState(monitor: monitor, underlyingWindow: window)
        onConnect(state, true)

        // Setup visibility tracking
        window.publisher(for: \.isVisible, options: .new)
            .filter({ $0 })
            .first()
            .sink(receiveValue: { isVisible in
                print("updating visibility state", isVisible)
                state.isVisible = isVisible
            })
            .store(bindTo: monitor)
    }

    private func windowWillClose() {
        onConnect(state, false)
        state = WindowState()
    }
}

extension View {
    func trackUnderlyingWindow(onConnect: @escaping (WindowState, Bool) -> Void) -> some View {
        return self.modifier(WindowTracker(onConnect: onConnect))
    }
}
