//
//  ContentView.swift
//  MyFirstImmersive
//
//  Created by Wilbur Wong on 2023/6/23.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @State var enlarge = false
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        VStack {
            Text(String(enlarge))
            RealityView { content in
                // Add the initial RealityKit content
                if let scene = try? await Entity(named: "Scene", in: realityKitContentBundle) {
                    content.add(scene)
                }
            } update: { content in
                // Update the RealityKit content when SwiftUI state changes
                if let scene = content.entities.first {
                    let uniformScale: Float = enlarge ? 1.4 : 1.0
                    scene.transform.scale = [uniformScale, uniformScale, uniformScale]
                }
            }
            .gesture(TapGesture().targetedToAnyEntity().onEnded { _ in
                enlarge.toggle()
            })
            
//            HStack {
                Button("Open") {
                    Task {
                        await openImmersiveSpace(id: "ImmersiveSpace")
                    }
                }
//                Button("Close") {
//                    Task {
//                        await dismissImmersiveSpace()
//                    }
//                }
//            }.padding()

            VStack {
                Toggle("Enlarge RealityView Content", isOn: $enlarge)
                    .toggleStyle(.button)
            }.padding().glassBackgroundEffect()
            
        }
    }
}

#Preview {
    ContentView()
}
