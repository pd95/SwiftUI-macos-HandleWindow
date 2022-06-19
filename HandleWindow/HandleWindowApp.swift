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
    }
}
