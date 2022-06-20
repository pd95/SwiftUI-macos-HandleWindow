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
            SettingsView()
        }
    }
}

struct SettingsView: View {
    @AppStorage("overwriteAutosaveName") private var overwriteAutosaveName = true
    @AppStorage("centered") private var windowCentered = true

    var body: some View {
        Form {
            GroupBox {
                VStack(alignment: .leading) {
                    Toggle("Overwrite frameAutosaveName", isOn: $overwriteAutosaveName)
                    Toggle("Center all new windows", isOn: $windowCentered)

                    Divider()

                    Button("Reset to defaults & restart", role: .destructive, action: resetToDefaults)
                        .frame(maxWidth: .infinity)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .padding()
        }
        .frame(maxWidth: 400)
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
