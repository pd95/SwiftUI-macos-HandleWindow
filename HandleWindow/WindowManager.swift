//
//  WindowManager.swift
//  HandleWindow
//
//  Created by Philipp on 29.06.22.
//

import AppKit
import Combine
import SwiftUI

typealias SceneID = String

struct SceneConfiguration: Identifiable {
    let id: SceneID
    let title: String
    let orderBy: Int
    //var defaultPosition: UnitPoint
    //var defaultSize: CGSize
    var contentType: Any.Type
    var isSingleWindow: Bool

    var keyboardShortcut: KeyboardShortcut?
}

extension SceneConfiguration: Comparable {
    static func < (lhs: SceneConfiguration, rhs: SceneConfiguration) -> Bool {
        lhs.orderBy < rhs.orderBy
    }

    static func == (lhs: SceneConfiguration, rhs: SceneConfiguration) -> Bool {
        lhs.id == rhs.id
    }
}

/// `WindowManager` is tracking and collecting information about installed scenes (`ManagedWindow` and `ManagedWindowGroup`)  and
/// will automatically handle URL open request based on the IDs of the window scenes.
/// It will also makes sure that single windows cannot be opened more than once. (This needs an override of the `New` command!)
/// In the future it should also handle `defaultPosition()` and `defaultSize()` for windows.
///
class WindowManager: ObservableObject {
    static let shared = WindowManager()

    private var scenes = [SceneID: SceneConfiguration]()
    private var scheme: String
    private var windows = [SceneID: [NSWindow]]()

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Ugly way to extract primary App URL scheme from Info.plist
        guard let infoDictionary = Bundle.main.infoDictionary,
              let urlTypes = infoDictionary["CFBundleURLTypes"] as? [[String: Any]],
              let firstURLType = urlTypes.first,
              let urlSchemes = firstURLType["CFBundleURLSchemes"] as? [String],
              let primaryURLScheme = urlSchemes.first
        else {
            fatalError("No URL scheme defined")
        }

        self.scheme = primaryURLScheme
    }

    func registerWindowGroup(id: SceneID, title: String, contentType: Any.Type, isSingleWindow: Bool) {
        guard scenes[id] == nil else {
            fatalError("Registered twice a window group with ID \(id)")
        }
        print("🟣 registered scene \(id) for \(contentType), \(type(of: contentType))")
        scenes[id] = SceneConfiguration(
            id: id,
            title: title,
            orderBy: scenes.count,
            contentType: contentType,
            isSingleWindow: isSingleWindow,
            keyboardShortcut: scenes.isEmpty ? KeyboardShortcut("N", modifiers: .command) : nil
        )
    }

    func registerOpenWindow(for sceneID: SceneID, window: NSWindow) {
        guard scenes[sceneID] != nil else {
            fatalError("No window group with ID \(sceneID)")
        }
        guard windows[sceneID, default: []].contains(window) == false else {
            return
        }
        print("🟣 registered window \(window) for \(sceneID))")
        windows[sceneID, default: []].append(window)

        NotificationCenter.default
            .publisher(for: NSWindow.willCloseNotification, object: window)
            .sink { [weak self, weak window] _ in
                print("🟣 removing window", window?.identifier ?? "")
                guard let self, let window else { return }
                self.windows[sceneID]?.removeAll(where: { $0 == window })
            }
            .store(in: &cancellables)
    }

    func openWindow(id: SceneID) {
        print("🟣 ", #function, id)
        guard let scene = scenes[id] else {
            fatalError("No WindowGroup registered with ID \(id)")
        }

        guard let url = URL(string: "\(scheme)://\(id)") else {
            fatalError("Unable to produce a valid url with \(id) and \(scheme)")
        }

        if scene.isSingleWindow, let window = windows[id]?.first {
            print("🟣 ", #function, "is single window")
            window.makeKeyAndOrderFront(nil)
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    // This handler is used to implement the "single window" behaviour: if a request to open a new window
    // is received we might bring the already existing window to the front.
    func openURLHandler(_ url: URL) -> OpenURLAction.Result {
        print("🟣", #function, url)
        if url.scheme == scheme {
            if let sceneID = url.host, let scene = scenes[sceneID] {
                if scene.isSingleWindow, let window = windows[sceneID]?.first {
                    print("🟣 ", #function, "reopening single window")
                    window.makeKeyAndOrderFront(nil)
                    return .handled
                }
            }
        }
        return .systemAction
    }

    @CommandsBuilder
    func commands() -> some Commands {
        CommandGroup(replacing: .newItem) {
            Menu("New") {
                ForEach(scenes.values.sorted()) { scene in
                    Button(LocalizedStringKey("New \(scene.title) Window"), action: { [weak self] in self?.openWindow(id: scene.id) })
                        .keyboardShortcut(scene.keyboardShortcut)
                }
            }
        }
    }
}



private struct WindowManagerEnvironmentKey: EnvironmentKey {
    static var defaultValue = WindowManager.shared
}

extension EnvironmentValues {
    var windowManager: WindowManager {
        self[WindowManagerEnvironmentKey.self]
    }
}
