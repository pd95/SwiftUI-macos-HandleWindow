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
        .defaultSize(CGSize(width: 400, height: 200))

        ManagedWindow(id: "tertiary") {
            ContentView()
        }
        .defaultPosition(.topTrailing)
        .defaultSize(CGSize(width: 600, height: 600))

        Settings {
            SettingsView()
        }
    }
}
