/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view presents a 360° destination image in an immersive space.
*/

import SwiftUI
import RealityKit
import Combine

/// A view that displays a 360 degree scene in which to watch video.
struct DestinationView: View {
    
    @State private var destination: Destination
    @State private var destinationChanged = false
    
    @Environment(PlayerModel.self) private var model
    
    init(_ destination: Destination) {
        self.destination = destination
    }
    
    var body: some View {
        RealityView { content in
            let rootEntity = Entity()
            rootEntity.addSkybox(for: destination)
            content.add(rootEntity)
        } update: { content in
            guard destinationChanged else { return }
            guard let entity = content.entities.first else { fatalError() }
            entity.updateTexture(for: destination)
            Task { @MainActor in
                destinationChanged = false
            }
        }
        // Handle the case where the app is already playing video in a destination and:
        // 1. The user opens the Up Next tab and navigates to a new item, or
        // 2. The user presses the "Play Next" button in the player UI.
        .onChange(of: model.currentItem) { oldValue, newValue in
            if let newValue, destination != newValue.destination {
                destination = newValue.destination
                destinationChanged = true
            }
        }
        .transition(.opacity)
    }
}

extension Entity {
    func addSkybox(for destination: Destination) {
        let subscription = TextureResource.loadAsync(named: destination.imageName).sink(
            receiveCompletion: {
                switch $0 {
                case .finished: break
                case .failure(let error): assertionFailure("\(error)")
                }
            },
            receiveValue: { [weak self] texture in
                guard let self = self else { return }
                var material = UnlitMaterial()
                material.color = .init(texture: .init(texture))
                self.components.set(ModelComponent(
                    mesh: .generateSphere(radius: 1E3),
                    materials: [material]
                ))
                self.scale *= .init(x: -1, y: 1, z: 1)
                self.transform.translation += SIMD3<Float>(0.0, 1.0, 0.0)
                
                // Rotate the sphere to show the best initial view of the space.
                updateRotation(for: destination)
            }
        )
        components.set(Entity.SubscriptionComponent(subscription: subscription))
    }
    
    func updateTexture(for destination: Destination) {
        let subscription = TextureResource.loadAsync(named: destination.imageName).sink(
            receiveCompletion: {
                switch $0 {
                case .finished: break
                case .failure(let error): assertionFailure("\(error)")
                }
            },
            receiveValue: { [weak self] texture in
                guard let self = self else { return }
                
                guard var modelComponent = self.components[ModelComponent.self] else {
                    fatalError("Should this be fatal? Probably.")
                }
                
                var material = UnlitMaterial()
                material.color = .init(texture: .init(texture))
                modelComponent.materials = [material]
                self.components.set(modelComponent)
                
                // Rotate the sphere to show the best initial view of the space.
                updateRotation(for: destination)
            }
        )
        components.set(Entity.SubscriptionComponent(subscription: subscription))
    }
    
    func updateRotation(for destination: Destination) {
        // Rotate the immersive space around the Y-axis set the user's
        // initial view of the immersive scene.
        let angle = Angle.degrees(destination.rotationDegrees)
        let rotation = simd_quatf(angle: Float(angle.radians), axis: SIMD3<Float>(0, 1, 0))
        self.transform.rotation = rotation
    }
    
    /// A container for the subscription that comes from asynchronous texture loads.
    ///
    /// In order for async loading callbacks to work we need to store
    /// a subscription somewhere. Storing it on a component will keep
    /// the subscription alive for as long as the component is attached.
    struct SubscriptionComponent: Component {
        var subscription: AnyCancellable
    }
}
