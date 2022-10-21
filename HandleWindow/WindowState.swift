//
//  WindowState.swift
//  HandleWindow
//
//  Created by Philipp on 21.10.22.
//

import SwiftUI

/// Storage for window related state and helpers
struct WindowState {
    var underlyingWindow = NSWindow()
    var isVisible: Bool = false

    var windowIdentifier: String {
        underlyingWindow.identifier?.rawValue ?? ""
    }

    var windowGroupID: String {
        windowIdentifier.split(separator: "-").first.map(String.init) ?? ""
    }

    var windowGroupInstance: Int {
        Int(windowIdentifier.split(separator: "-").last.map({ String($0) }) ?? "") ?? 0
    }
}
