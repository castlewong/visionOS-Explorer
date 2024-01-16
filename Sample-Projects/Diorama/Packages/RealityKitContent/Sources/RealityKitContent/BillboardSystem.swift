/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A RealityKit system that keeps entities with a BillboardComponent facing toward the camera.
*/

import ARKit
import RealityKit
import SwiftUI

public struct BillboardSystem: System {

    static let query = EntityQuery(where: .has(RealityKitContent.BillboardComponent.self))

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
                print("Error: \(error)")
            }
        }
    }

    public func update(context: SceneUpdateContext) {

        let entities = context.scene.performQuery(Self.query).map({ $0 })

        guard !entities.isEmpty,
                let pose = worldTrackingProvider.queryPose(atTimestamp: CACurrentMediaTime()) else { return }

        let cameraTransform = Transform(matrix: pose.originFromDeviceTransform)

        for entity in entities {

            let translation = entity.transform.translation

            entity.look(at: cameraTransform.translation,
                        from: entity.position(relativeTo: nil),
                        relativeTo: nil,
                        forward: .positiveZ)

            entity.transform.translation = translation
        }
    }
}

#Preview {
    RealityView { content, attachments in
        BillboardSystem.registerSystem()
        BillboardComponent.registerComponent()
        
        if let entity = attachments.entity(for: "previewTag") {

            let billboardComponent = BillboardComponent()
            entity.components[BillboardComponent.self] = billboardComponent
            
            content.add(entity)
        }
    } attachments: {
        Text("Preview")
            .font(.system(size: 100))
            .background(.pink)
            .tag("previewTag")
    }
    .previewLayout(.sizeThatFits)
}
