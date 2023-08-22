//
//  ContentView.swift
//  SnowSky
//
//  Created by Wilbur Wong on 2023/8/22.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        
        NavigationSplitView {
            List{
                Text("Tem")
            }
            .navigationTitle("Sidebar")
        } detail: {
            VStack{
                Model3D(named: "Scene", bundle: realityKitContentBundle)
                    .padding(.bottom, 50)
                Text("Hello")
                Toggle("Show ImmersiveSpace", isOn: $showImmersiveSpace)
                    .toggleStyle(.button)
                    .padding(.top, 50)
            }
            .navigationTitle("Content")
            .padding()
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
