//
//  MyFirstImmersiveApp.swift
//  MyFirstImmersive
//
//  Created by Wilbur Wong on 2023/6/23.
//

import SwiftUI

@main
struct MyFirstImmersiveApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }.windowStyle(.volumetric)
        
        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
        
    }
}
