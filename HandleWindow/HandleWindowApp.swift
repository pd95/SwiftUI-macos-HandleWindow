//
//  HandleWindowApp.swift
//  HandleWindow
//
//  Created by Philipp on 18.06.22.
//

import SwiftUI

func fakeWindowPosition() {
    print("🔴", #function)

    let main = NSScreen.main!
    print("frame", main.frame)
    print("visibleFrame", main.visibleFrame)

    let screenWidth = main.frame.width
    let screenHeightWithoutMenuBar = main.frame.height - 25 // menu bar
    let visibleFrame = main.visibleFrame

    let contentWidth = WIDTH
    let contentHeight = HEIGHT + 28 // window title bar

    let old = UserDefaults.standard.string(forKey: "NSWindow Frame main-AppWindow-1")
    print("old", old ?? "")

    let windowX = visibleFrame.midX - contentWidth/2
    let windowY = visibleFrame.midY - contentHeight/2

    let newFramePreference = "\(Int(windowX)) \(Int(windowY)) \(Int(contentWidth)) \(Int(contentHeight)) 0 0 \(Int(screenWidth)) \(Int(screenHeightWithoutMenuBar))"
    print("newFramePreference", newFramePreference)
    UserDefaults.standard.set(newFramePreference, forKey: "NSWindow Frame main-AppWindow-1")
}

@main
struct HandleWindowApp: App {
    init() {
        // Approach 1: fake the initial position by overwriting the preferences
        //fakeWindowPosition()
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentWindowWrapper()
        }
    }
}
