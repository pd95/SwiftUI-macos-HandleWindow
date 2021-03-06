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
            content
                .trackUnderlyingWindow { window in
                    print("onConnect", window?.identifier?.rawValue ?? "-")
                    if let window {
                        windowManager.registerOpenWindow(for: id, window: window)
                    }
                } onVisibilityChange: { window, isVisible in
                    print("isVisible", isVisible, window.frame, window.frameAutosaveName, window.identifier?.rawValue ?? "-")
                    if isSingleWindow {
                        // Ensure we always use the same frameAutosaveName to store the location of the window
                        window.setFrameAutosaveName("\(id)-AppWindow-1")
                    }

                    if isVisible {
                        windowManager.applyDefaultPosition(to: window, for: id)
                    }
                }
                .environment(\.openURL, OpenURLAction(handler: windowManager.openURLHandler))
        }
        .handlesExternalEvents(matching: Set([id]))
        .commands {
            windowManager.commands()
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
        WindowManager.shared.setDefaultPosition(position, for: id)
        return self
    }
}

extension ManagedWindow {
    func defaultPosition(_ position: UnitPoint) -> Self {
        WindowManager.shared.setDefaultPosition(position, for: id)
        return self
    }
}
