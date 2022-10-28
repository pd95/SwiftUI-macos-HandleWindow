//
//  WindowManager.swift
//  HandleWindow
//
//  Created by Philipp on 29.06.22.
//

import AppKit
import Combine
import SwiftUI

/// `WindowManager` is tracking and collecting information about installed scenes (`ManagedWindow` and `ManagedWindowGroup`)  and
/// will automatically handle URL open request based on the IDs of the window scenes.
/// It will also makes sure that single windows cannot be opened more than once. (This needs an override of the `New` command!)
/// In the future it should also handle `defaultPosition()` and `defaultSize()` for windows.
///
class WindowManager: ObservableObject {
    static let shared = WindowManager()

    private var scheme: String
    private var windows = [SceneID: [NSWindow]]()

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

    func registerWindow(for sceneID: SceneID, window: NSWindow) {
        guard let config = SceneConfiguration.configuration(for: sceneID) else {
            fatalError("No window group with ID \(sceneID)")
        }

        guard windows[sceneID, default: []].contains(window) == false else {
            return
        }

        // Restore frame descriptor from UserDefaults
        if let restorableFrameDescriptor = sceneFrameFromUserDefaults(sceneID),
           config.sceneFrameDescriptor == nil  {
            SceneConfiguration.update(sceneID: sceneID) { scene in
                scene.sceneFrameDescriptor = restorableFrameDescriptor
            }
        }

        print("🟣 registered new window for \(sceneID)")
        windows[sceneID, default: []].append(window)
    }

    func unregisterWindow(for sceneID: SceneID, window: NSWindow) {
        guard SceneConfiguration.exists(withID: sceneID) else {
            fatalError("No window group with ID \(sceneID)")
        }
        guard let index = windows[sceneID, default: []].firstIndex(of: window) else {
            print("🔴 window \(window.identifier?.rawValue ?? "-") not found!")
            return
        }
        print("🟣 removing window \(window.identifier?.rawValue ?? "-") for \(sceneID)")
        windows[sceneID]?.remove(at: index)
        if windows[sceneID]?.count == 0 {
            let frameDescriptor = window.frameDescriptor
            print("🟣 saving position of last window to UserDefaults: \(frameDescriptor)")
            SceneConfiguration.update(sceneID: sceneID) { scene in
                scene.sceneFrameDescriptor = frameDescriptor
            }
            saveSceneFrameToUserDefaults(sceneID, frameDescriptor: frameDescriptor)
        }
    }

    func openWindow(id: SceneID) {
        print("🟣 ", #function, id)
        guard let scene = SceneConfiguration.configuration(for: id) else {
            fatalError("No WindowGroup registered with ID \(id)")
        }

        guard let host = id.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
              let url = URL(string: "\(scheme)://\(host)")
        else {
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
            if let sceneID = url.host, let scene = SceneConfiguration.configuration(for: sceneID) {
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
                ForEach(SceneConfiguration.allScenes.values.sorted()
                    .filter({ $0.title != nil || $0.isMain })
                ) { scene in
                    Button(LocalizedStringKey(scene.commandName), action: { [weak self] in self?.openWindow(id: scene.id) })
                        .keyboardShortcut(scene.keyboardShortcut)
                }
            }
        }
    }

    // MARK: - Handling default positioning of window

    private func sceneFrameAutosaveNameInUserDefaults(_ sceneID: SceneID) -> String {
        "NSWindow Frame \(sceneID)-AppWindow-1"
    }

    private func sceneFrameFromUserDefaults(_ sceneID: SceneID) -> String? {
        let key = sceneFrameAutosaveNameInUserDefaults(sceneID)
        let value = UserDefaults.standard.string(forKey: key)
        print("  Reading \(key): \(String(describing: value))")
        return value
    }

    private func saveSceneFrameToUserDefaults(_ sceneID: SceneID, frameDescriptor: String) {
        let key = sceneFrameAutosaveNameInUserDefaults(sceneID)
        print("  Writing \(key): \(frameDescriptor)")
        UserDefaults.standard.set(frameDescriptor, forKey: sceneFrameAutosaveNameInUserDefaults(sceneID))
    }

    func setInitialFrame(to window: NSWindow, for id: SceneID) {
        print("🟣 ", #function, "  window is currently at: \(window.frame)")

        // Position relative to last opened window
        if let lastWindow = windows[id]?.last(where: { $0 != window }) {

            let lastFrame = lastWindow.frame
            window.setFrame(lastFrame, display: false)
            window.setFrameTopLeftPoint(
                window.cascadeTopLeft(from: CGPoint(x: lastFrame.minX,
                                                    y: lastFrame.maxY))
            )
            print("  placed new window relative to last window at", window.frame)

        } else {
            let scene = SceneConfiguration.configuration(for: id)

            // Place window where last window was located on closing
            if let savedFrameDescriptor = scene?.sceneFrameDescriptor {
                print("  placing at last saved position: ", savedFrameDescriptor)
                window.setFrame(from: savedFrameDescriptor)

            } else {
                let defaultPosition = scene?.defaultPosition
                let defaultSize = scene?.defaultSize

                if let defaultPosition {
                    // Place at default location (if window is opened for the first time)
                    print("  placing at UnitPoint position", defaultPosition)
                    let frameOrigin = frameOriginForUnitPointPosition(window, position: defaultPosition, size: defaultSize)

                    if let defaultSize {
                        print("  sizing ", defaultSize)
                        window.setFrame(CGRect(origin: frameOrigin, size: defaultSize), display: false)
                    } else {
                        window.setFrameOrigin(frameOrigin)
                    }
                } else if let defaultSize {
                    print("  sizing ", defaultSize)
                    window.setFrame(CGRect(origin: window.frame.origin, size: defaultSize), display: false)
                }
            }
        }
        print("  window frame: \(window.frame)")
    }

    private func frameOriginForUnitPointPosition(_ window: NSWindow, position: UnitPoint, size: CGSize?) -> CGPoint {
        guard let screen = window.screen else {
            print("🔴 window is not attached to a screen")
            return .zero
        }

        let visibleFrame = screen.visibleFrame
        let windowSize = size ?? window.frame.size
        let screenSize = CGSize(width: visibleFrame.width-windowSize.width, height: visibleFrame.height-windowSize.height)

        let projectedPoint = CGPoint(
            x: visibleFrame.origin.x + min(max(0, position.x * screenSize.width), visibleFrame.width),
            y: visibleFrame.origin.y + max(0, (1-position.y) * screenSize.height)
        )

        return projectedPoint
    }
}

private extension NSWindow {
    /// Returns scene ID based on window identifier (=first part)
    var sceneID: SceneID? {
        guard let parts = identifier?.rawValue.split(separator: "-"),
              parts.count == 3 && parts[1] == "AppWindow",
              let sceneIdentifier = parts.first
        else {
            return nil
        }
        return String(sceneIdentifier)
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
