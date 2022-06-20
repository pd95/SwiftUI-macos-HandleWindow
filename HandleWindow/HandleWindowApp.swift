//
//  HandleWindowApp.swift
//  HandleWindow
//
//  Created by Philipp on 18.06.22.
//

import SwiftUI

@main
struct HandleWindowApp: App {

    var body: some Scene {
        WindowGroup("Main", id: "main") {
            ContentWindowWrapper()
        }
        .handlesExternalEvents(matching: ["main"])

        WindowGroup("Secondary", id: "secondary") {
            ContentView()
                .trackUnderlyingWindow()
        }
        .handlesExternalEvents(matching: ["secondary"])

        Settings {
            SettingsView()
        }
    }
}
