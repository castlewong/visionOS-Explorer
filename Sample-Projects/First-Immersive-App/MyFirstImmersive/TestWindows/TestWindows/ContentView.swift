//
//  ContentView.swift
//  TestWindows
//
//  Created by Wilbur Wong on 2023/6/23.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            List {
                Text("Item")
            }
            .navigationTitle("Sidebar")
        } detail: {
            VStack {
                Model3D(named: "Scene", bundle: realityKitContentBundle)
                    .padding(.bottom, 50)

                Text("Hello, world!")
            }
            .navigationTitle("Content")
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
