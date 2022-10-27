//
//  WindowMonitor.swift
//  HandleWindow
//
//  Created by Philipp on 21.10.22.
//

import Combine
import SwiftUI

class WindowMonitor: NSObject {
    fileprivate var cancellables = Set<AnyCancellable>()

    private let onConnect: (NSWindow, WindowMonitor) -> Void
    private let onWillClose: () -> Void
    private weak var window: NSWindow?

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
        cancellables.forEach(self.remove)
    }

    func store(cancellable: AnyCancellable) {
        cancellables.insert(cancellable)
    }

    func remove(cancellable: AnyCancellable) {
        cancellable.cancel()
        cancellables.remove(cancellable)
    }

    /// This function uses KVO to observe the `window` property of `view` and calls `onConnect()`
    /// and starts observing window visibility and closing.
    func monitorView(_ view: NSView) {
        view.publisher(for: \.window, options: .new)
            .compactMap({ $0 })
            .first()
            .sink { [weak self] newWindow in
                guard let self else { return }
                self.window = newWindow
                self.monitorClosing(of: newWindow)
                self.onConnect(newWindow, self)
            }
            .store(bindTo: self)
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
            .store(bindTo: self)
    }
}

extension AnyCancellable {
    func store(bindTo monitor: WindowMonitor) {
        store(in: &monitor.cancellables)
    }
}
