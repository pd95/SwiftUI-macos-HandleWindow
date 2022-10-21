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
                WindowAccessor(onConnect: {
                    let isConnect = $0 != nil
                    if isConnect, let window = $0 {
                        self.state.underlyingWindow = window
                    }
                    onConnect?(self.state, isConnect)
                }, onVisibilityChange: { window, isVisible in
                    state.isVisible = isVisible
                    onVisibilityChange?(window, isVisible)
                })
            )
            .environment(\.window, state)
    }
}

extension View {
    func trackUnderlyingWindow(onConnect: ((WindowState, Bool) -> Void)? = nil, onVisibilityChange: ((NSWindow, Bool) -> Void)? = nil) -> some View {
        return self.modifier(WindowTracker(onConnect: onConnect, onVisibilityChange: onVisibilityChange))
    }
}
