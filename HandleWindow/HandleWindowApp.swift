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
            ContentView()
        }
        .defaultPosition(.topLeading)

        ManagedWindowGroup("Secondary", id: "secondary") {
            ContentView()
        }
        .defaultPosition(.center)

        Settings {
            SettingsView()
        }
    }
}
