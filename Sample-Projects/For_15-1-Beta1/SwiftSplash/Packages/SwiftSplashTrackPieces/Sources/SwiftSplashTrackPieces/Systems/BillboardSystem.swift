/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that keeps entities facing the camera at all times.
*/

import ARKit
import Foundation
import OSLog
import RealityKit
import simd
import SwiftUI

/// An ECS system that points all entities containing a billboard component at the camera.
public struct BillboardSystem: System {
    
    static let query = EntityQuery(where: .has(SwiftSplashTrackPieces.BillboardComponent.self))
    
    private let arkitSession = ARKitSession()
    private let worldTrackingProvider = WorldTrackingProvider()
    
    public init(scene: RealityKit.Scene) {
        setUpSession()
    }
    
    func setUpSession() {
        
        Task {
            do {
                try await arkitSession.run([worldTrackingProvider])
            } catch {
                os_log(.info, "Error: \(error)")
            }
        }
    }
    
    public func update(context: SceneUpdateContext) {
        
        let entities = context.scene.performQuery(Self.query).map({ $0 })
        
        guard !entities.isEmpty,
              let pose = worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else { return }
        
        let cameraTransform = Transform(matrix: pose.originFromAnchorTransform)
        
        for entity in entities {
            entity.look(at: cameraTransform.translation,
                        from: entity.scenePosition,
                        relativeTo: nil,
                        forward: .positiveZ)
        }
    }
}
