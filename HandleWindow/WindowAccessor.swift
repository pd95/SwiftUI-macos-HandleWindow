//
//  WindowAccessor.swift
//  HandleWindow
//
//  Created by Philipp on 18.06.22.
//

import SwiftUI
import Combine

/// This view will add a `NSView` to the hierarchy and track its `window` property to
/// get a handle to the `NSWindow`.
/// The coordinator object is responsible for this KVO observation, triggering the relevant callbacks and updating `WindowState`
struct WindowAccessor: NSViewRepresentable {
    let onConnect: (NSWindow?) -> Void
    let onVisibilityChange: ((NSWindow, Bool) -> Void)?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.monitorView(view)
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
    }

    func makeCoordinator() -> WindowMonitor {
        WindowMonitor(onConnect, onVisibilityChange: onVisibilityChange)
    }

    class WindowMonitor: NSObject {
        private var cancellables = Set<AnyCancellable>()
        private var viewTracker: Cancellable?

        private var onConnect: ((NSWindow?) -> Void)
        private var onVisibilityChange: ((NSWindow, Bool) -> Void)?

        init(_ onChange: @escaping (NSWindow?) -> Void, onVisibilityChange: ((NSWindow, Bool) -> Void)?) {
            print("🟡 Coordinator", #function)
            self.onConnect = onChange
            self.onVisibilityChange = onVisibilityChange
        }

        deinit {
            print("🟡 Coordinator", #function)
        }

        func dismantle() {
            print("🟡 Coordinator", #function)
            cancellables.removeAll()
        }

        /// This function uses KVO to observe the `window` property of `view` and calls `onConnect()`
        /// and starts observing window visibility and closing.
        func monitorView(_ view: NSView) {
            viewTracker = view.publisher(for: \.window)
                .removeDuplicates()
                .dropFirst()
                .sink { [weak self] newWindow in
                    guard let self = self else { return }
                    self.onConnect(newWindow)
                    if let newWindow = newWindow {
                        self.monitorClosing(of: newWindow)
                        self.monitorVisibility(newWindow)
                        self.viewTracker = nil
                    }
                }
        }

        /// This function uses notifications to track closing of our views underlying `window`
        private func monitorClosing(of window: NSWindow) {
            NotificationCenter.default
                .publisher(for: NSWindow.willCloseNotification, object: window)
                .sink { [weak self] notification in
                    guard let self = self else { return }
                    self.onConnect(nil)
                    self.cancellables.removeAll()
                }
                .store(in: &cancellables)
        }

        /// This function uses KVO to track `isVisible` property of `window`
        private func monitorVisibility(_ window: NSWindow) {
            window.publisher(for: \.isVisible)
                .dropFirst()  // we know: the first value is not interesting
                .sink(receiveValue: { [weak self, weak window] isVisible in
                    guard let window else { return }
                    self?.onVisibilityChange?(window, isVisible)
                })
                .store(in: &cancellables)
        }
    }
}
