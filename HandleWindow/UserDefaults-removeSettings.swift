//
//  UserDefaults-removeSettings.swift
//  HandleWindow
//
//  Created by Philipp on 05.07.22.
//

import Foundation

extension UserDefaults {
    func removeAppSettings() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
        self.removePersistentDomain(forName: bundleIdentifier)
        self.synchronize()
    }
}
