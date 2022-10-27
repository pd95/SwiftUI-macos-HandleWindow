//
//  SceneConfiguration.swift
//  HandleWindow
//
//  Created by Philipp on 27.10.22.
//

import SwiftUI

typealias SceneID = String

struct SceneConfiguration: Identifiable {
    let id: SceneID
    let isMain: Bool
    let title: String?
    let orderBy: Int
    var defaultPosition: UnitPoint?
    //var defaultSize: CGSize
    var contentType: Any.Type
    var isSingleWindow: Bool

    var sceneFrameDescriptor: String?

    var keyboardShortcut: KeyboardShortcut? {
        isMain ? KeyboardShortcut("N", modifiers: .command) : nil
    }

    var commandName: String {
        if let title {
            return "New \(title) Window"
        } else {
            return "New Window"
        }
    }
}

extension SceneConfiguration: Comparable {
    static func < (lhs: SceneConfiguration, rhs: SceneConfiguration) -> Bool {
        lhs.orderBy < rhs.orderBy
    }

    static func == (lhs: SceneConfiguration, rhs: SceneConfiguration) -> Bool {
        lhs.id == rhs.id
    }
}
