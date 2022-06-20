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
        WindowGroup(id: "main") {
            ContentWindowWrapper()
        }

        Settings {
            GroupBox {
                Button("Reset to defaults & restart", action: resetToDefaults)
                    .padding()
            }
            .padding()
        }
    }

    private func resetToDefaults() {
        let defaults = UserDefaults.standard

        let identifier = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: identifier)
        defaults.synchronize()


        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        NSApplication.shared.stop(nil)
    }
}
