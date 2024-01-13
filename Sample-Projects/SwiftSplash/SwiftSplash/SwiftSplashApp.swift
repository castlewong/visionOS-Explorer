/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app class.
*/

import SwiftUI
import SwiftSplashTrackPieces
import RealityKit

@main
@MainActor
struct SwiftSplash: App {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissWindow) var dismissWindow
    
    /// Pass the app's state object to all SwiftUI views as an environment object.
    @State private var appState = AppState()
    
    @State private var immersionStyle: ImmersionStyle = .mixed
    
    var body: some SwiftUI.Scene {
        WindowGroup(id: "SwiftSplash") {
            ContentView()
                .environment(appState)
                .onChange(of: appState.phase.isImmersed) { _, showMRView in
                    if showMRView {
                        Task {
                            appState.isImmersiveViewShown = true
                            await openImmersiveSpace(id: "Track")
                            dismissWindow(id: "SwiftSplash")
                            appState.music = .build
                        }
                    }
                }
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        
        // Present a mixed immersive space in expanded mode.
        ImmersiveSpace(id: "Track") {
            TrackBuildingView()
                .environment(appState)
        }
        .immersionStyle(selection: $immersionStyle, in: .mixed)
    }
    init() {
        BillboardSystem.registerSystem()
        BillboardComponent.registerComponent()
        
        ConnectableComponent.registerComponent()
        ConnectableStateComponent.registerComponent()
        
        IdleAnimationComponent.registerComponent()
        RideAnimationComponent.registerComponent()
        GlowComponent.registerComponent()
        RideWaterComponent.registerComponent()
    }
}
