/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that animates trails on the terrain.
*/
import RealityKit
import SwiftUI

public final class TrailAnimationSystem: System {

    static let query = EntityQuery(where: .has(RealityKitContent.TrailComponent.self))

    public static let materialParameterName = "TrailProgress"

    private let secondsPerLoop: TimeInterval = 5

    private var time: TimeInterval = 0

    public init(scene: RealityKit.Scene) { }

    public func update(context: SceneUpdateContext) {
        
        time += context.deltaTime
        
        let seconds = time / secondsPerLoop
        let progress = seconds.remainder
        
        do {
            try context.scene.performQuery(Self.query).forEach { entity in
                
                guard var material = entity.shaderGraphMaterial else { return }
                try material.setParameter(name: Self.materialParameterName, value: .float(Float(progress)))
                
                if var component = entity.modelComponent {
                    component.materials = [material]
                    entity.components.set(component)
                }
            }
        } catch {
            print("problem: \(error)")
        }
    }
}

extension TimeInterval {
    var remainder: Double {
        modf(self).1
    }
}

#Preview {
    RealityView { content in
        
        TrailAnimationSystem.registerSystem()
        RealityKitContent.TrailComponent.registerComponent()
        
        if let root = try? await Entity(named: "TrailPath_Export/TrailPath_Export.usdc", in: RealityKitContentBundle) {
            content.add(root)
            root.findEntity(named: "Catalina_TrailA")?.components.set(TrailComponent())
            
        }
    }
    .previewLayout(.sizeThatFits)
}

