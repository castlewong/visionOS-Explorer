/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A RealityKit system that moves multiple components together, like a school of fish or a swarm of birds.
*/

import Foundation
import RealityKit
import RealityKitContent

public struct FlockingSystem: System {
    static let flockingQuery = EntityQuery(where: .has(FlockingComponent.self) )
    let maxForce = 0.5
    
    let separationDistance: Float = 0.1
    let maxSeparation: Float = 0.001
    
    let alignmentDistance: Float = 0.1
    let maxAlignment: Float = 0.002
    
    let cohesionDistance: Float = 0.05
    let maxCohesion: Float = 0.002
    
    let seekSpeed: Float = 0.001
    let maxSeek: Float = 0.001
    
    let maxRotation: Float = .pi / 45.0
    let maxSpeed: Float = 0.5
    
    let relativeEntityName = "Root"
    let startTime = Date()
    
    public init(scene: RealityKit.Scene) { }
    
    public func update(context: SceneUpdateContext) {
        let birds = context.scene.performQuery(Self.flockingQuery)
        var accelerationTable: [Entity: SIMD3<Float>] = [:]
        let relativeEntity = context.scene.findEntity(named: relativeEntityName)
        
        for bird in birds {
            accelerationTable[bird] = SIMD3<Float>(repeating: 0)
        }
        
        // Add forces together to an accumulated acceleration table.
        for bird in birds {
            guard let flockingComponent = bird.components[FlockingComponent.self],
                  var birdAcceleration = accelerationTable[bird] else { continue }
            
            let birdVelocity = flockingComponent.velocity
            let seekPosition = flockingComponent.seekPosition
            
            let birdPosition = bird.position(relativeTo: relativeEntity)
            
            var separationVelocityAccumulation = SIMD3<Float>(repeating: 0)
            var separationCount: Int = 0
            
            var alignmentVelocityAccumulation = SIMD3<Float>(repeating: 0)
            var alignmentCount: Int = 0
            
            var cohesionPositionAccumulation = SIMD3<Float>(repeating: 0)
            var cohesionCount: Int = 0
            
            for otherBird in birds {
                guard bird.id != otherBird.id else { continue }
                let otherBirdPosition = otherBird.position(relativeTo: relativeEntity)
                let distance = length(otherBirdPosition - birdPosition)
                
                // Handle separation.
                if distance <= separationDistance && distance > 0 {
                    separationVelocityAccumulation += normalize(birdPosition - otherBirdPosition) / distance
                    separationCount += 1
                }
                
                // Handle alignment.
                if distance <= alignmentDistance && distance > 0 {
                    let otherVelocity: SIMD3<Float> = otherBird.components[FlockingComponent.self]?.velocity ?? SIMD3<Float>(repeating: 0.0)
                    alignmentVelocityAccumulation += otherVelocity
                    alignmentCount += 1
                }
                
                // Handle cohesion.
                if distance <= cohesionDistance && distance > 0 {
                    cohesionPositionAccumulation += otherBirdPosition
                    cohesionCount += 1
                }
            }
            
            let desiredVelocity = normalize(seekPosition - birdPosition) * seekSpeed
            var seekForce = desiredVelocity - birdVelocity
            seekForce.clamp(lowerBound: SIMD3<Float>(repeating: -maxSeek),
                            upperBound: SIMD3<Float>(repeating: maxSeek))
            birdAcceleration += seekForce
            
            // Handle separation.
            if separationCount > 0 {
                let separationVelocity = separationVelocityAccumulation / Float(separationCount)
                if length(separationVelocity) > 0 {
                    var separationAcceleration = separationVelocity - birdVelocity
                    separationAcceleration.clamp(lowerBound: SIMD3<Float>(repeating: -maxSeparation),
                                                 upperBound: SIMD3<Float>(repeating: maxSeparation))
                    birdAcceleration += separationAcceleration
                }
            }
            
            // Handle alignment.
            if alignmentCount > 0 {
                let alignmentVelocity = alignmentVelocityAccumulation / Float(alignmentCount)
                var alignmentAcceleration = alignmentVelocity - birdVelocity
                alignmentAcceleration.clamp(lowerBound: SIMD3<Float>(repeating: -maxAlignment),
                                            upperBound: SIMD3<Float>(repeating: maxAlignment))
                birdAcceleration += alignmentAcceleration
            }
            
            // Handle cohesion.
            if cohesionCount > 0 {
                let cohesionCenter = cohesionPositionAccumulation / Float(cohesionCount)
                let desiredVelocity = normalize(cohesionCenter - birdPosition)
                var cohesionAcceleration = desiredVelocity - birdVelocity
                cohesionAcceleration.clamp(lowerBound: SIMD3<Float>(repeating: -maxCohesion),
                                           upperBound: SIMD3<Float>(repeating: -maxCohesion))
                birdAcceleration += cohesionAcceleration
            }
            
            accelerationTable[bird] = birdAcceleration
        }
        
        // Update the position of the birds and store a new calculated velocity based on acceleration.
        for bird in birds {
            if var flockingComponent = bird.components[FlockingComponent.self] {
                let birdPosition = bird.position(relativeTo: relativeEntity)
                
                if let acceleration = accelerationTable[bird] {
                    flockingComponent.velocity += acceleration
                    
                    // Clamp speed if over certain amount.
                    if length(flockingComponent.velocity) > maxSpeed {
                        flockingComponent.velocity = normalize(flockingComponent.velocity) * maxSpeed
                    }
                }
                
                let newPosition = birdPosition + flockingComponent.velocity
                
                // Set the bird's orientation.
                let birdOrientation = bird.orientation(relativeTo: relativeEntity)
                bird.look(at: flockingComponent.seekPosition, from: birdPosition, relativeTo: relativeEntity, forward: .positiveZ)
                let deltaRotation = birdOrientation.inverse * bird.orientation
                if deltaRotation.angle > maxRotation {
                    bird.orientation = birdOrientation
                    bird.orientation *= simd_quatf(angle: maxRotation, axis: deltaRotation.axis)
                }
                
                bird.setPosition(newPosition, relativeTo: relativeEntity)
                bird.components[FlockingComponent.self] = flockingComponent
            }
        }
        
        // Choose a new seek position based on the petal shape. These are specified as polar coordinates.
        let currentDateTime = Date()
        let polarAngle = startTime.distance(to: currentDateTime) / 10.0
        let radius = cos(2 * polarAngle)
        let x = radius * cos(polarAngle)
        let z = radius * sin(polarAngle)
        var newSeekPosition = SIMD3<Float>(Float(x), 0, Float(z))
        newSeekPosition.y = Float(cos(polarAngle)) * 0.2 + 1.6
        
        for bird in birds {
            if var flockingComponent = bird.components[FlockingComponent.self] {
                flockingComponent.seekPosition = newSeekPosition
                bird.components[FlockingComponent.self] = flockingComponent
            }
        }
    }
}
