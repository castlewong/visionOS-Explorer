/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A large sphere that has an image of the night sky on its inner surface.
*/

import SwiftUI
import RealityKit

/// A large sphere that has an image of the night sky on its inner surface.
///
/// When centered on the viewer, this entity creates the illusion of floating
/// in space.
struct Starfield: View {
    var body: some View {
        RealityView { content in
            // Create a material with a star field on it.
            guard let resource = try? await TextureResource(named: "Starfield") else {
                // If the asset isn't available, something is wrong with the app.
                fatalError("Unable to load starfield texture.")
            }
            var material = UnlitMaterial()
            material.color = .init(texture: .init(resource))

            // Attach the material to a large sphere.
            let entity = Entity()
            entity.components.set(ModelComponent(
                mesh: .generateSphere(radius: 1000),
                materials: [material]
            ))

            // Ensure the texture image points inward at the viewer.
            entity.scale *= .init(x: -1, y: 1, z: 1)

            content.add(entity)
        }
    }
}
