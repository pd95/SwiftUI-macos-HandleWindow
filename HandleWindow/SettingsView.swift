//
//  SettingsView.swift
//  HandleWindow
//
//  Created by Philipp on 20.06.22.
//

import SwiftUI

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

                    Button("Reset to defaults & quit", role: .destructive, action: resetToDefaults)
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

        NSApplication.shared.stop(nil)
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
