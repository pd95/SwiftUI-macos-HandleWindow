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
    let onConnect: (NSWindow) -> Void
    let onDisconnect: (() -> Void)?
    let onVisibilityChange: ((NSWindow, Bool) -> Void)?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.monitorView(view)
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
    }

    func makeCoordinator() -> WindowMonitor {
        WindowMonitor(onConnect, onDisconnect: onDisconnect, onVisibilityChange: onVisibilityChange)
    }

    class WindowMonitor: NSObject {
        private var cancellables = Set<AnyCancellable>()
        private var viewTracker: Cancellable?

        private let onConnect: ((NSWindow) -> Void)
        private let onDisconnect: (() -> Void)?
        private let onVisibilityChange: ((NSWindow, Bool) -> Void)?
        private var window: NSWindow?

        init(_ onChange: @escaping (NSWindow) -> Void, onDisconnect: (() -> Void)?, onVisibilityChange: ((NSWindow, Bool) -> Void)?) {
            print("🟡 Coordinator", #function)
            self.onConnect = onChange
            self.onDisconnect = onDisconnect
            self.onVisibilityChange = onVisibilityChange
        }

        deinit {
            print("🟡 Coordinator", #function)
        }

        private func dismantle() {
            print("🟡 Coordinator", #function)
            window = nil
            cancellables.removeAll()
        }

        /// This function uses KVO to observe the `window` property of `view` and calls `onConnect()`
        /// and starts observing window visibility and closing.
        func monitorView(_ view: NSView) {
            viewTracker = view.publisher(for: \.window)
                .compactMap({ $0 })
                .sink { [weak self] newWindow in
                    guard let self = self else { return }
                    self.onConnect(newWindow)
                    self.window = newWindow
                    self.monitorClosing(of: newWindow)
                    if self.onVisibilityChange != nil {
                        self.observeWindowAttribute(for: \.isVisible, options: [.prior, .new], using: { [weak self] (window, isVisible) -> Void in
                            self?.dumpState(window, "visibleChange")
                            self?.onVisibilityChange?(window, isVisible)
                        })
                    }
                    self.observeWindowAttribute(for: \.frame, using: { [weak self] window, frame in
                        self?.dumpState(window, "frameChange")
                    })
                    self.viewTracker = nil
                }
        }

        private func dumpState(_ window: NSWindow, _ comment: String = "") {
            print("⚫️ \(window.identifier?.rawValue ?? "-") \(comment) frame: \(window.frame) isVisible: \(window.isVisible) isKeyWindow: \(window.isKeyWindow)")
        }

        /// This function uses notifications to track closing of our views underlying `window`
        private func monitorClosing(of window: NSWindow) {
            NotificationCenter.default
                .publisher(for: NSWindow.willCloseNotification, object: window)
                .sink { [weak self] notification in
                    guard let self = self else { return }
                    self.onDisconnect?()
                    self.dismantle()
                }
                .store(in: &cancellables)
        }

        /// Utility function to observe any `NSWindow` attribute for changes (based on KVO)
        func observeWindowAttribute<Value>(
            for keyPath: KeyPath<NSWindow, Value>,
            options: NSKeyValueObservingOptions = [.new],
            using handler: @escaping (NSWindow, Value) -> Bool
        ) {
            guard let window else {
                fatalError("Cannot observe keyPath \(keyPath) without initialized window")
            }
            var cancellable: AnyCancellable!
            cancellable = window.publisher(for: keyPath, options: options)
                .sink(receiveValue: { [weak self, weak window] value in
                    guard let window else { return }
                    let shouldContinue = handler(window, value)
                    if !shouldContinue {
                        cancellable.cancel()
                        self?.cancellables.remove(cancellable)
                    }
                })
            cancellables.insert(cancellable)
        }

        func observeWindowAttribute<Value>(
            for keyPath: KeyPath<NSWindow, Value>,
            options: NSKeyValueObservingOptions = [.new],
            using handler: @escaping (NSWindow, Value) -> Void
        ) {
            observeWindowAttribute(for: keyPath, options: options, using: {
                handler($0, $1)
                return true
            })
        }
    }
}
