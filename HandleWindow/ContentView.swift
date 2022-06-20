//
//  ContentView.swift
//  HandleWindow
//
//  Created by Philipp on 18.06.22.
//

import SwiftUI
import Combine

let WIDTH: CGFloat = 400
let HEIGHT: CGFloat = 200

struct ContentWindowWrapper: View {

    @AppStorage("overwriteAutosaveName") private var overwriteAutosaveName = true
    @AppStorage("centered") private var centered = true

    var body: some View {
        ContentView()
            //.trackUnderlyingWindow()
            .trackUnderlyingWindow(onVisibilityChange: { window, isVisible in
                print("isVisible", isVisible, window.frame, window.frameAutosaveName, window.identifier?.rawValue ?? "-")
                if isVisible {
                    print(window.frameAutosaveName, window.frame)

                    // Make sure this window stores its position under the same preference
                    if overwriteAutosaveName {
                        window.setFrameAutosaveName("main-AppWindow-1")
                    }

                    // Place window at a specific position
                    print("🟢 centered", centered)
                    if centered {
                        placeWindow(window)
                    }
                }
            })
    }

    private func placeWindow(_ window: NSWindow) {
        let main = NSScreen.main!
        let visibleFrame = main.visibleFrame
        let windowSize = window.frame.size

        let windowX = visibleFrame.midX - windowSize.width/2
        let windowY = visibleFrame.midY - windowSize.height/2

        let desiredOrigin = CGPoint(x: windowX, y: windowY)
        window.setFrameOrigin(desiredOrigin)
        print(#function, window.frame)
    }
}

struct ContentView: View {
    @Environment(\.window) var window

    var body: some View {
        print(Self.self, #function, window)
        return VStack {
            Text("it finally works!")
                .font(.largeTitle)

            if let window {
                Text(window.underlyingWindow?.frameAutosaveName ?? "-")
                Text("\(String(describing: window))")

                Button("Dump") {
                    dump(window)
                }
            }
        }
        .padding()
        .frame(width: WIDTH, height: HEIGHT, alignment: .center)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
