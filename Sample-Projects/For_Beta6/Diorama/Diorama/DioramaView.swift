/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that holds the app's immersive content.
*/

import SwiftUI
import RealityKit
import RealityKitContent

struct DioramaView: View {
    @Environment(\.dismiss) private var dismiss

    var viewModel: ViewModel

    static let markersQuery = EntityQuery(where: .has(PointOfInterestComponent.self))
    static let runtimeQuery = EntityQuery(where: .has(PointOfInterestRuntimeComponent.self))
    
    @State private var subscriptions = [EventSubscription]()
    @State private var attachmentsProvider = AttachmentsProvider()

    var body: some View {
        @Bindable var viewModel = viewModel
        
        RealityView { content, _ in
            do {
                let entity = try await Entity(named: "DioramaAssembled", in: RealityKitContent.RealityKitContentBundle)
                viewModel.rootEntity = entity
                content.add(entity)
                viewModel.updateScale()
                
                // Offset the scene so it doesn't appear underneath the user or conflict with the main window.
                entity.position = SIMD3<Float>(0, 0, -2)
                
                setupBirds(rootEntity: entity)

                subscriptions.append(content.subscribe(to: ComponentEvents.DidAdd.self, componentType: PointOfInterestComponent.self, { event in
                    createLearnMoreView(for: event.entity)
                }))

                subscriptions.append(content.subscribe(to: ComponentEvents.DidAdd.self, componentType: TrailComponent.self, { event in

                    let trail = event.entity

                    if let parentRegion = trail.parent?.components[PointOfInterestComponent.self] {
                        trail.components.set(RegionSpecificComponent(region: parentRegion.region))
                    }

                    // Trail entities need a TrailOpacityComponents so they can fade in and out.
                    trail.components.set(ControlledOpacityComponent(shouldShow: false))

                    trail.components.set(OpacityComponent(opacity: 0.0))

                    viewModel.updateRegionSpecificOpacity()
                }))

            } catch {
                print("Error in RealityView's make: \(error)")
            }
            
        } update: { content, attachments in

            viewModel.setupAudio()

            // Add attachment entities to marked entities. First, find all entities that have the
            // PointOfInterestRuntimeComponent, which means they've created an attachment.
            viewModel.rootEntity?.scene?.performQuery(Self.runtimeQuery).forEach { entity in

                guard let component = entity.components[PointOfInterestRuntimeComponent.self] else { return }

                // Get the entity from the collection of attachments keyed by tag.
                guard let attachmentEntity = attachments.entity(for: component.attachmentTag) else { return }
                
                // Attachments are region-specific. They react when the slider changes from one map to the other.
                // Take the region configured in Reality Composer Pro and give it to the corresponding attachment
                // entity. These entities also need OpacityComponents so they can fade in and out as the map changes
                if let pointOfInterestComponent = entity.components[PointOfInterestComponent.self] {
                    attachmentEntity.components.set(RegionSpecificComponent(region: pointOfInterestComponent.region))
                    attachmentEntity.components.set(OpacityComponent(opacity: 0))
                }
                
                viewModel.rootEntity?.addChild(attachmentEntity)
                attachmentEntity.setPosition([0, 0.2, 0], relativeTo: entity)
                attachmentEntity.components.set(BillboardComponent())
            }
            
            viewModel.updateRegionSpecificOpacity()
            viewModel.updateTerrainMaterial()

        } attachments: {
            
            ForEach(attachmentsProvider.sortedTagViewPairs, id: \.tag) { pair in
                pair.view
            }
        }
    }
    
    private func createLearnMoreView(for entity: Entity) {
        
        // If this entity already has a RuntimeComponent, don't add another one.
        guard entity.components[PointOfInterestRuntimeComponent.self] == nil else { return }
        
        // Get this entity's PointOfInterestComponent, which is in the Reality Composer Pro project.
        guard let pointOfInterest = entity.components[PointOfInterestComponent.self] else { return }
        
        // Highlight the trail entity associated with this location marker entity.
        let trailEntity: Entity? = entity.children.first(where: { $0.hasMaterialParameter(named: TrailAnimationSystem.materialParameterName) })
        
        let tag: ObjectIdentifier = entity.id
        
        let view = LearnMoreView(name: pointOfInterest.name,
                                 description: pointOfInterest.description ?? "",
                                 imageNames: pointOfInterest.imageNames,
                                 trail: trailEntity,
                                 viewModel: viewModel)
            .tag(tag)
        
        entity.components[PointOfInterestRuntimeComponent.self] = PointOfInterestRuntimeComponent(attachmentTag: tag)
        
        attachmentsProvider.attachments[tag] = AnyView(view)
    }
    
    private func setupBirds(rootEntity entity: Entity) {
        guard let birds = entity.findEntity(named: "Birds") else { return }
        for bird in birds.children {
            bird.components[FlockingComponent.self] = FlockingComponent()

            guard let animationResource = bird.availableAnimations.first else { continue }
            let controller = bird.playAnimation(animationResource.repeat())
            controller.speed = Float.random(in: 1..<2.5)
        }
    }
}

#Preview {
    DioramaView(viewModel: ViewModel())
        .previewLayout(.sizeThatFits)
}
