//
//  HandleWindowApp.swift
//  HandleWindow
//
//  Created by Philipp on 18.06.22.
//

import SwiftUI

@main
struct HandleWindowApp: App {
    @Environment(\.windowManager) var windowManager

    var body: some Scene {
        ManagedWindow("Main", id: "main") {
            ContentView(groupID: "main")
        }
        .defaultPosition(.topLeading)

        ManagedWindowGroup("Secondary", id: "secondary") {
            ContentView(groupID: "secondary")
        }
        .defaultPosition(.center)

        Settings {
            SettingsView()
        }
    }
}
