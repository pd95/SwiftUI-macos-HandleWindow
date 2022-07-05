//
//  SettingsView.swift
//  HandleWindow
//
//  Created by Philipp on 20.06.22.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            GroupBox {
                Button("Reset to defaults & quit", role: .destructive, action: resetToDefaults)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .padding()
        }
        .frame(maxWidth: 400)
    }

    private func resetToDefaults() {
        UserDefaults.standard.removeAppSettings()
        NSApplication.shared.stop(nil)
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
