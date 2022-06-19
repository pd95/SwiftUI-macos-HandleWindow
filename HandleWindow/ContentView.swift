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
    var body: some View {
        ContentView()
            .handleWindowEvents(onAppear: { window, isVisible in
                print("isVisible", isVisible, window.frame, window.frameAutosaveName, window.identifier?.rawValue ?? "-")
                if isVisible {
                    print(window.frameAutosaveName, window.frame)

                    // Make sure this window stores its position under the same preference
                    window.setFrameAutosaveName("main-AppWindow-1")
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
    @Environment(\.currentWindow) var currentWindow

    var body: some View {
        VStack {
            Text("it finally works!")
                .font(.largeTitle)

            Text(currentWindow?.frameAutosaveName ?? "-")
            Text("\(String(describing: currentWindow))")

            Button("Dump") {
                dump(self)
            }
        }
        .frame(width: WIDTH, height: HEIGHT, alignment: .center)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
