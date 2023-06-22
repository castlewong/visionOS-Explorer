/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A convenience method for moving model objects with RealityKit animation.
*/

import RealityKit
import SwiftUI

extension Entity {
    /// Updates the scale, rotation, and position of a RealityKit entity
    /// using optional animation.
    func updateTransform(
        scale: SIMD3<Float>? = nil,
        rotation: simd_quatf? = nil,
        translation: SIMD3<Float>? = nil,
        withAnimation: Bool = false
    ) {
        let end = Transform(
            scale: scale ?? transform.scale,
            rotation: rotation ?? orientation,
            translation: translation ?? transform.translation)
        
        guard end != transform else { return }
        guard withAnimation else {
            transform = end
            return
        }
        
        do {
            let transformAnimation = FromToByAnimation(
                name: "transform",
                from: transform,
                to: end,
                duration: 0.25,
                timing: .easeInOut,
                isAdditive: false,
                bindTarget: .transform)
            let resource = try AnimationResource.generate(with: transformAnimation)
            playAnimation(resource)
        } catch {
            // Skip the animation and jump to the end.
            transform = end
        }
    }
}
