//
//  ManagedWindow.swift
//  HandleWindow
//
//  Created by Philipp on 29.06.22.
//

import SwiftUI

struct ManagedWindowGroup<Content: View>: Scene {

    @Environment(\.windowManager) private var windowManager

    private let title: String
    fileprivate let id: SceneID
    fileprivate let content: Content
    fileprivate let isSingleWindow: Bool

    public init(_ title: String, id: String, @ViewBuilder content: () -> Content) {
        self.init(title, id: id, isSingleWindow: false, content: content)
    }

    fileprivate init(_ title: String, id: String, isSingleWindow: Bool, @ViewBuilder content: () -> Content) {
        self.title = title
        self.id = id
        self.isSingleWindow = isSingleWindow
        self.content = content()
        WindowManager.shared.registerWindowGroup(id: id, title: title, contentType: Content.self, isSingleWindow: isSingleWindow)
    }

    var body: some Scene {
        WindowGroup(title, id: id) {
            WrappedContent(sceneID: id, content: content)
                .trackUnderlyingWindow { windowState, isConnecting in
                    print("onConnect", windowState.windowIdentifier, isConnecting)
                    if isConnecting {
                        windowManager.registerWindow(for: id, window: windowState.underlyingWindow)
                    } else {
                        windowManager.unregisterWindow(for: id, window: windowState.underlyingWindow)
                    }
                }
                .environment(\.openURL, OpenURLAction(handler: windowManager.openURLHandler))
        }
        .handlesExternalEvents(matching: Set([id]))
        .commands {
            windowManager.commands()
        }
    }

    private struct WrappedContent<Content: View>: View {
        @Environment(\.window) private var windowState
        @Environment(\.windowManager) private var windowManager

        let sceneID: String
        let content: Content

        var body: some View {
            content
                .onChange(of: windowState.isVisible) { isVisible in
                    if NSApplication.shared.isActive && isVisible {
                        windowManager.setInitialFrame(to: windowState.underlyingWindow, for: sceneID)
                    }
                }
        }
    }
}


/// `ManagedWindow` is a special variant of `ManagedWindowGroup` which tries to avoid multiple windows of the same type
struct ManagedWindow<Content: View>: Scene {

    fileprivate let id: SceneID
    private let content: ManagedWindowGroup<Content>

    public init(_ title: String, id: String, @ViewBuilder content: () -> Content) {
        self.id = id
        self.content = ManagedWindowGroup(title, id: id, isSingleWindow: true, content: content)
    }

    var body: some Scene {
        content
    }
}

extension ManagedWindowGroup {
    func defaultPosition(_ position: UnitPoint) -> Self {
        WindowManager.shared.setDefaultUnitPointPosition(position, for: id)
        return self
    }
}

extension ManagedWindow {
    func defaultPosition(_ position: UnitPoint) -> Self {
        WindowManager.shared.setDefaultUnitPointPosition(position, for: id)
        return self
    }
}
