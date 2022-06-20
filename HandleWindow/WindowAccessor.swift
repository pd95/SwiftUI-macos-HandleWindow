//
//  WindowAccessor.swift
//  HandleWindow
//
//  Created by Philipp on 18.06.22.
//

import SwiftUI
import Combine

struct WindowAccessor: NSViewRepresentable {
    var onConnect: ((NSWindow?) -> Void)? = nil
    var onAppear: ((NSWindow, Bool) -> Void)? = nil

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.monitorView(view)
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
    }

    func makeCoordinator() -> WindowMonitor {
        WindowMonitor(onConnect: onConnect, onAppear: onAppear)
    }

    class WindowMonitor: NSObject {
        private var cancellables = Set<AnyCancellable>()
        private var onConnect: ((NSWindow?) -> Void)?
        private var onAppear: ((NSWindow, Bool) -> Void)?

        init(onConnect: ((NSWindow?) -> Void)?, onAppear: ((NSWindow, Bool) -> Void)?) {
            print("🟡 Coordinator", #function)
            self.onConnect = onConnect
            self.onAppear = onAppear
        }

        deinit {
            print("🟡 Coordinator", #function)
        }

        func dismantle() {
            print("🟡 Coordinator", #function)
            cancellables.removeAll()
            onConnect = nil
            onAppear = nil
        }

        /// This function uses KVO to observe the `window` property of `view` and calls `onChange()`
        func monitorView(_ view: NSView) {
            view.publisher(for: \.window)
                .removeDuplicates()
                .dropFirst()
                .sink { [weak self] newWindow in
                    guard let self = self else { return }
                    self.onConnect?(newWindow)
                    if let newWindow = newWindow {
                        self.monitorClosing(of: newWindow)
                        if self.onAppear != nil {
                            self.monitorVisibility(newWindow)
                        }
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
                    self.onConnect?(nil)
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
                    self.onAppear?(window, isVisible)
                })
                .store(in: &cancellables)
        }
    }
}


private struct CurrentWindowEnvironmentKey: EnvironmentKey {
    static var defaultValue: NSWindow? = nil
}

extension EnvironmentValues {
    var currentWindow: NSWindow? {
        get { self[CurrentWindowEnvironmentKey.self] }
        set { self[CurrentWindowEnvironmentKey.self] = newValue }
    }
}

private struct CurrentWindowTracker: ViewModifier {
    @State private var window: NSWindow?

    let onConnect: ((NSWindow?) -> Void)?
    let onAppear: ((NSWindow, Bool) -> Void)?

    func body(content: Content) -> some View {
        print(Self.self, #function)
        return content
            .environment(\.currentWindow, window)
            .background(
                WindowAccessor(
                    onConnect: { newWindow in
                        onConnect?(newWindow)
                        window = newWindow
                    },
                    onAppear: onAppear
                )
            )
    }
}


extension View {
    func handleWindowEvents(onConnect: ((NSWindow?) -> Void)? = nil, onAppear: ((NSWindow, Bool) -> Void)? = nil) -> some View {
        return self.modifier(CurrentWindowTracker(onConnect: onConnect, onAppear: onAppear))
    }
}
