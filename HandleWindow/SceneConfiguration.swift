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

// MARK: - Scene configuration management

extension SceneConfiguration {
    static var allScenes = [SceneID: SceneConfiguration]()

    static func register(id: SceneID, title: String?, contentType: Any.Type, isSingleWindow: Bool) -> SceneID {
        print("🟣 registering scene \(id) for \(contentType), \(type(of: contentType))")

        var id = id
        if allScenes[id] != nil {
            var counter = 0
            print("  duplicate scene ID \(id)")
            while allScenes[id] != nil {
                counter += 1
                let newID = "\(id)-\(counter)"
                print("  trying \(newID)...")
                if allScenes[newID] == nil {
                    id = newID
                }
            }
            print("  using \(id)")
        }

        let sceneConfig = SceneConfiguration(
            id: id,
            isMain: allScenes.isEmpty,
            title: title,
            orderBy: allScenes.count,
            contentType: contentType,
            isSingleWindow: isSingleWindow
        )
        allScenes[id] = sceneConfig

        print("🟣 registered scene \(id) as \(sceneConfig)")
        return sceneConfig.id
    }

    static func configuration(for sceneID: SceneID) -> SceneConfiguration? {
        allScenes[sceneID]
    }

    static func exists(withID id: SceneID) -> Bool {
        configuration(for: id) != nil
    }

    static func update(sceneID: SceneID, action: (inout SceneConfiguration) -> Void) {
        guard var config = allScenes[sceneID] else {
            fatalError("No scene for \(sceneID) found")
        }
        action(&config)
        allScenes[sceneID] = config
    }
}
