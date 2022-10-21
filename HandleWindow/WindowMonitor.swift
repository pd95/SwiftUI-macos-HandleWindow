//
//  WindowMonitor.swift
//  HandleWindow
//
//  Created by Philipp on 21.10.22.
//

import SwiftUI

protocol WindowMonitor {
    func observeWindowAttribute<Value>(
        for keyPath: KeyPath<NSWindow, Value>,
        options: NSKeyValueObservingOptions,
        using handler: @escaping (NSWindow, Value) -> Bool
    )

    func observeWindowAttribute<Value>(
        for keyPath: KeyPath<NSWindow, Value>,
        options: NSKeyValueObservingOptions,
        using handler: @escaping (NSWindow, Value) -> Void
    )
}
