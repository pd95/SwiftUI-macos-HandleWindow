//
//  WindowAccessor.swift
//  HandleWindow
//
//  Created by Philipp on 18.06.22.
//

import SwiftUI
import Combine

struct WindowAccessor: NSViewRepresentable {
    @Binding var holder: WindowState

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.monitorView(view)
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
    }

    func makeCoordinator() -> WindowMonitor {
        WindowMonitor(self)
    }

    class WindowMonitor: NSObject {
        private var cancellables = Set<AnyCancellable>()

        @Binding private var holder: WindowState

        init(_ parent: WindowAccessor) {
            print("🟡 Coordinator", #function)
            self._holder = parent._holder
        }

        deinit {
            print("🟡 Coordinator", #function)
        }

        func dismantle() {
            print("🟡 Coordinator", #function)
            cancellables.removeAll()
            holder.underlyingWindow = nil
        }

        /// This function uses KVO to observe the `window` property of `view` and calls `onChange()`
        func monitorView(_ view: NSView) {
            view.publisher(for: \.window)
                .removeDuplicates()
                .dropFirst()
                .sink { [weak self] newWindow in
                    guard let self = self else { return }
                    self.holder.underlyingWindow = newWindow
                    self.holder.onConnect?(newWindow)
                    if let newWindow = newWindow {
                        self.monitorClosing(of: newWindow)
                        self.monitorVisibility(newWindow)
                    }
                }
                .store(in: &cancellables)
        }

        /// This function uses notifications to track closing of `window`
        private func monitorClosing(of window: NSWindow) {
            NotificationCenter.default
                .publisher(for: NSWindow.willCloseNotification, object: window)
                .sink { [weak self] notification in
                    guard let self = self else { return }
                    self.holder.onConnect?(nil)
                    self.dismantle()
                }
                .store(in: &cancellables)
        }

        /// This function uses KVO to track `isVisible` property of `window`
        private func monitorVisibility(_ window: NSWindow) {
            window.publisher(for: \.isVisible)
                .dropFirst()  // we know: the first value is not interesting
                .sink(receiveValue: { [weak self, weak window] isVisible in
                    guard let self, let window else { return }
                    self.holder.isVisible = isVisible
                    self.holder.onAppear?(window, isVisible)
                })
                .store(in: &cancellables)
        }
    }
}


private struct CurrentWindowEnvironmentKey: EnvironmentKey {
    static var defaultValue: WindowState?
}

extension EnvironmentValues {
    var currentWindow: NSWindow? {
        self[CurrentWindowEnvironmentKey.self]?.underlyingWindow
    }
}

extension EnvironmentValues {
    var window: WindowState? {
        get { self[CurrentWindowEnvironmentKey.self] }
        set { self[CurrentWindowEnvironmentKey.self] = newValue }
    }
}

private struct CurrentWindowTracker: ViewModifier {
    @State private var state: WindowState

    init(onConnect: ((NSWindow?) -> Void)?, onAppear: ((NSWindow, Bool) -> Void)?) {
        _state = State(initialValue: WindowState(
            underlyingWindow: nil,
            onConnect: onConnect,
            onAppear: onAppear
        ))
    }

    func body(content: Content) -> some View {
        print(Self.self, #function, state)
        return content
            .background(WindowAccessor(holder: $state))
            .environment(\.window, state)
    }
}

struct WindowState {
    var underlyingWindow: NSWindow?

    var onConnect: ((NSWindow?) -> Void)?
    var onAppear: ((NSWindow, Bool) -> Void)?
    var isVisible: Bool = false
}


extension View {
    func handleWindowEvents(onConnect: ((NSWindow?) -> Void)? = nil, onAppear: ((NSWindow, Bool) -> Void)? = nil) -> some View {
        return self.modifier(CurrentWindowTracker(onConnect: onConnect, onAppear: onAppear))
    }
}
