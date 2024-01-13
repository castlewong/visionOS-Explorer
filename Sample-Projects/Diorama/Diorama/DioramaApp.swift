/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app definition.
*/

import SwiftUI
import RealityKitContent
import ARKit
import RealityKit

@main
struct DioramaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let immersiveSpaceIdentifier = "Immersive"
    
    @State private var viewModel = ViewModel()

    init() {
        RealityKitContent.PointOfInterestComponent.registerComponent()
        PointOfInterestRuntimeComponent.registerComponent()
        RealityKitContent.TrailComponent.registerComponent()
        RealityKitContent.BillboardComponent.registerComponent()
        ControlledOpacityComponent.registerComponent()
        RealityKitContent.RegionSpecificComponent.registerComponent()
        
        RealityKitContent.BillboardSystem.registerSystem()
        RealityKitContent.TrailAnimationSystem.registerSystem()

        FlockingComponent.registerComponent()
        FlockingSystem.registerSystem()
    }
    
    var body: some SwiftUI.Scene {

        WindowGroup {
            ContentView(spaceId: immersiveSpaceIdentifier,
                        viewModel: viewModel)
        }
        .windowStyle(.plain)

        ImmersiveSpace(id: immersiveSpaceIdentifier) {
            DioramaView(viewModel: viewModel)
        }

    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: UIApplication) -> Bool {
        return true
    }
}
