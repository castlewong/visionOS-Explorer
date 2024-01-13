/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app structure.
*/

import SwiftUI
import RealityKit

/// The structure of the Happy Beam app: a main window and a Full Space for gameplay.
@main
struct HappyBeamApp: App {
    @StateObject private var gameModel = GameModel()
    @State private var immersionState: ImmersionStyle = .mixed
    
    var body: some SwiftUI.Scene {
        WindowGroup("HappyBeam", id: "happyBeamApp") {
            HappyBeam()
                .environmentObject(gameModel)
                .onAppear {
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                        return
                    }
                        
                    windowScene.requestGeometryUpdate(.Reality(resizingRestrictions: UIWindowScene.ResizingRestrictions.none))
                }
        }
        .windowStyle(.plain)
        
        ImmersiveSpace(id: "happyBeam") {
            HappyBeamSpace(gestureModel: HeartGestureModelContainer.heartGestureModel)
                .environmentObject(gameModel)
        }
        .immersionStyle(selection: $immersionState, in: .mixed)
    }
}

@MainActor
enum HeartGestureModelContainer {
    private(set) static var heartGestureModel = HeartGestureModel()
}
