//
//  ContentView.swift
//  HandleWindow
//
//  Created by Philipp on 18.06.22.
//

import SwiftUI
import Combine

struct ContentView: View {
    @Environment(\.sceneID) private var sceneID
    @Environment(\.window) private var window
    @Environment(\.openURL) private var openURL

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
                        Text("Scene ID:")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text(sceneID)
                            .fixedSize()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack {
                        Text("Window Identifier:")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text(window.windowIdentifier)
                            .fixedSize()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack {
                        Text("Window Group ID:")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text(window.windowGroupID)
                            .fixedSize()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack {
                        Text("Window Instance:")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text(window.windowGroupInstance, format: .number)
                            .fixedSize()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack {
                        Text("frameAutosaveName:")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text(window.underlyingWindow.frameAutosaveName)
                            .fixedSize()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                HStack {
                    Toggle("Has changes", isOn: $hasChanges)
                    Button("Try close") {
                        window.close()
                    }

                    Button("Dump window state") {
                        dump(window)
                    }
                }

                HStack {
                    Button("Main") {
                        openURL(URL(string: "handleWindow://main")!)
                    }
                    .disabled(sceneID == "main")

                    Button("Secondary") {
                        openURL(URL(string: "handleWindow://secondary")!)
                    }
                    .disabled(sceneID == "secondary")

                    Button("Tertiary") {
                        openURL(URL(string: "handleWindow://tertiary")!)
                    }
                    .disabled(sceneID == "tertiary")
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
        ContentView()
    }
}
