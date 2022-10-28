//
//  ManagedWindow.swift
//  HandleWindow
//
//  Created by Philipp on 29.06.22.
//

import SwiftUI


private struct SceneIDEnvironmentKey: EnvironmentKey {
    static var defaultValue: SceneID = ""
}

extension EnvironmentValues {
    var sceneID: SceneID {
        get { self[SceneIDEnvironmentKey.self] }
        set { self[SceneIDEnvironmentKey.self] = newValue }
    }
}

struct ManagedWindowGroup<Content: View>: Scene {

    @Environment(\.windowManager) private var windowManager

    private let title: String?
    fileprivate let id: SceneID
    fileprivate let content: Content
    fileprivate let isSingleWindow: Bool

    public init(_ title: String, id: String, @ViewBuilder content: () -> Content) {
        self.init(title: title, id: id, isSingleWindow: false, content: content)
    }

    public init(_ title: String, @ViewBuilder content: () -> Content) {
        self.init(title: title, id: nil, isSingleWindow: false, content: content)
    }

    public init(id: String, @ViewBuilder content: () -> Content) {
        self.init(title: nil, id: id, isSingleWindow: false, content: content)
    }

    public init(@ViewBuilder content: () -> Content) {
        self.init(title: nil, id: nil, isSingleWindow: false, content: content)
    }

    fileprivate init(title: String?, id: String?, isSingleWindow: Bool, @ViewBuilder content: () -> Content) {
        self.title = title
        self.isSingleWindow = isSingleWindow
        self.content = content()
        self.id = SceneConfiguration.register(id: id ?? String(describing: Content.self), title: title, contentType: Content.self, isSingleWindow: isSingleWindow)
    }

    private func wrappedContent() -> some View {
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
            .environment(\.sceneID, id)
    }

    private var windowGroup: some Scene {
        if let title {
            return WindowGroup(title, id: id, content: wrappedContent)
        } else {
            return WindowGroup(id: id, content: wrappedContent)
        }
    }

    var body: some Scene {
        windowGroup
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
                    if isVisible {
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
        self.content = ManagedWindowGroup(title: title, id: id, isSingleWindow: true, content: content)
    }

    public init(id: String, @ViewBuilder content: () -> Content) {
        self.id = id
        self.content = ManagedWindowGroup(title: nil, id: id, isSingleWindow: true, content: content)
    }

    public init(@ViewBuilder content: () -> Content) {
        let content = ManagedWindowGroup(title: nil, id: nil, isSingleWindow: true, content: content)
        self.id = content.id
        self.content = content
    }

    var body: some Scene {
        content
    }
}

extension ManagedWindowGroup {
    func defaultPosition(_ position: UnitPoint) -> Self {
        SceneConfiguration.update(sceneID: id) { scene in
            scene.defaultPosition = position
        }
        return self
    }

    func defaultSize(_ size: CGSize) -> Self {
        SceneConfiguration.update(sceneID: id) { scene in
            scene.defaultSize = size
        }
        return self
    }
}

extension ManagedWindow {
    func defaultPosition(_ position: UnitPoint) -> Self {
        SceneConfiguration.update(sceneID: id) { scene in
            scene.defaultPosition = position
        }
        return self
    }

    func defaultSize(_ size: CGSize) -> Self {
        SceneConfiguration.update(sceneID: id) { scene in
            scene.defaultSize = size
        }
        return self
    }
}
