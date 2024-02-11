//
//  SnowApp.swift
//  Snow
//
//  Created by Wilbur Wong on 2023/8/22.
//

import SwiftUI

@main
struct SnowApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
