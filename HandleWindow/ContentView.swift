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

struct ContentView: View {
    @State var window : NSWindow?
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        VStack {
            Text("it finally works!")
                .font(.largeTitle)

            Text(window?.frameAutosaveName ?? "-")
        }
        .frame(width: WIDTH, height: HEIGHT, alignment: .center)
        .background(WindowAccessor { newWindow in
            if let newWindow {

                monitorVisibility(window: newWindow)

            } else {
                // window closed: release all references
                self.window = nil
                self.cancellables.removeAll()
            }
        })
    }

    private func monitorVisibility(window: NSWindow) {
        window.publisher(for: \.isVisible)
            .dropFirst()  // we know: the first value is not interesting
            .sink(receiveValue: { isVisible in
                print("isVisible", isVisible, window.frame, window.frameAutosaveName)
                if isVisible {
                    // Keep a handle to this window
                    //self.window = window

                    print(window.frameAutosaveName, window.frame)

                    // Make sure this window stores its position under the same preference
                    window.setFrameAutosaveName("main-AppWindow-1")

                    // Place the window
                    //placeWindow(window)
                }
            })
            .store(in: &cancellables)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
