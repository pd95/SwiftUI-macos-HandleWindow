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
    let onConnect: (NSWindow, WindowMonitor) -> Void
    let onWillClose: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.monitorView(view)
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
    }

    func makeCoordinator() -> WindowMonitor {
        WindowMonitor(onConnect, onWillClose: onWillClose)
    }

    class WindowMonitor: NSObject {
        private var cancellables = Set<AnyCancellable>()
        private var viewTracker: Cancellable?

        private let onConnect: (NSWindow, WindowMonitor) -> Void
        private let onWillClose: () -> Void
        private var window: NSWindow?

        init(_ onChange: @escaping (NSWindow, WindowMonitor) -> Void, onWillClose: @escaping () -> Void) {
            print("🟡 Coordinator", #function)
            self.onConnect = onChange
            self.onWillClose = onWillClose
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
            viewTracker = view.publisher(for: \.window, options: .new)
                .sink { [weak self] newWindow in
                    guard let self, let newWindow else { return }
                    self.window = newWindow
                    self.monitorClosing(of: newWindow)
                    self.onConnect(newWindow, self)

                    self.viewTracker = nil
                }
        }

        /// This function uses notifications to track closing of our views underlying `window`
        private func monitorClosing(of window: NSWindow) {
            NotificationCenter.default
                .publisher(for: NSWindow.willCloseNotification, object: window)
                .sink { [weak self] notification in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.onWillClose()
                        self.dismantle()
                    }
                }
                .store(in: &cancellables)
        }
    }
}


extension WindowAccessor.WindowMonitor: WindowMonitor {

    /// Utility function to observe any `NSWindow` attribute for changes (based on KVO)
    func observeWindowAttribute<Value>(
        for keyPath: KeyPath<NSWindow, Value>,
        options: NSKeyValueObservingOptions,
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
        options: NSKeyValueObservingOptions,
        using handler: @escaping (NSWindow, Value) -> Void
    ) {
        observeWindowAttribute(for: keyPath, options: options, using: {
            handler($0, $1)
            return true
        })
    }
}
