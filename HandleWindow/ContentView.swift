//
//  ContentView.swift
//  HandleWindow
//
//  Created by Philipp on 18.06.22.
//

import SwiftUI
import Combine

struct ContentView: View {
    @Environment(\.window) var window
    @Environment(\.openURL) var openURL

    let groupID: String

    @State private var hasChanges = false

    var body: some View {
        let _ = print("\(Self.self): body executed for ", window.windowGroupID, window.windowGroupInstance)
        let _ = Self._printChanges()
        VStack(spacing: 20) {
            Text("it finally works!")
                .font(.largeTitle)

            if let window {
                VStack {
                    HStack {
                        Text("Window Identifier:")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text(window.windowIdentifier)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack {
                        Text("Window Group ID:")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text(window.windowGroupID)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack {
                        Text("Window Instance:")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text(window.windowGroupInstance, format: .number)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack {
                        Text("frameAutosaveName:")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text(window.underlyingWindow.frameAutosaveName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                HStack {
                    Toggle("Has changes", isOn: $hasChanges)
                    Button("Try close") {
                        window.close()
                    }
                }

                HStack {
                    if groupID == "secondary" {
                        Button("Main") {
                            openURL(URL(string: "handleWindow://main")!)
                        }
                    } else {
                        Button("Secondary") {
                            openURL(URL(string: "handleWindow://secondary")!)
                        }
                    }

                    Button("Dump") {
                        dump(window)
                    }
                }
            }
        }
        .onChange(of: window.isVisible, perform: { isVisible in
            if isVisible {
                window.registerShouldClose(callback: {
                    hasChanges == false
                })
            }
        })
        .frame(minWidth: 300)
        .fixedSize(horizontal: true, vertical: false)
        .padding(20)
        .frame(maxWidth: window.screenSize?.width, maxHeight: window.screenSize?.height)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(groupID: "main")
    }
}
