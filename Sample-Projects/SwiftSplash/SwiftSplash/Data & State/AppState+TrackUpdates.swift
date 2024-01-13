/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that holds application state functions that update app visuals based on current state.
*/

import ARKit
import Combine
import Foundation
import SwiftSplashTrackPieces
import RealityKit
import UIKit
extension AppState {
    
    func updateVisuals() {
        markSelectedPieces()
        updateMarkerPosition()
        updateSelection()
        updatePower()
        if let lastPiece = lastConnectedPiece {
            placeMarker(at: lastPiece)
        }
    }
    
    func updateConnections() {
        let entities = root.scene?.performQuery(connectableQuery)
        entities?.forEach() { piece in
            findClosestPieces(for: piece)
        }
        
        var entity: Entity? = goalPiece
        var seenEntities = [Entity]()
        while entity != nil {
            // If the player creates a track that loops back onto itself, this
            // prevents an infinite loop from happening when iterating through
            // the pieces.
            if let entity = entity {
                if seenEntities.contains(entity) {
                    logger.error("Player created a loop. Refusing to connect.")
                    break
                }
                seenEntities.append(entity)
            }
            
            entity = entity?.connectableStateComponent?.previousPiece
        }
    }
    
    func updatePower() {
        
        // Set the power on all connectable entities to off.
        let entities = root.scene?.performQuery(connectableQuery)
        entities?.forEach { entity in
            entity.setPower(isPowered: false)
        }
        
        // Set connected entities to on.
        var entity = startPiece
        var seenEntities = [Entity]()
        while entity != nil {
            // If the player creates a track that loops back onto itself, this
            // prevents an infinite loop from happening when iterating through
            // the pieces.
            if let entity = entity {
                if seenEntities.contains(entity) {
                    logger.error("Player created a loop. Refusing to connect.")
                    break
                }
                seenEntities.append(entity)
            }
            entity?.setPower(isPowered: true)
            entity = entity?.connectableStateComponent?.nextPiece
        }
    }
    
    func updateSelection() {
        let entities = root.scene?.performQuery(connectableQuery)
        
        var seenEntities = [Entity]()
        entities?.forEach { entity in
            // If the player creates a track that loops back onto itself, this
            // prevents an infinite loop from happening when iterating through
            // the pieces.
            if seenEntities.contains(entity) {
                logger.error("Player created a loop. Refusing to connect.")
                return
                
            }
            seenEntities.append(entity)
            guard entity.name != placePieceMarkerName else {
                return
            }
            guard let state = entity.connectableStateComponent else {
                return
            }
            
            entity.forEachDescendant(withComponent: GlowComponent.self) { entity, component in
                entity.isEnabled = state.isSelected
            }
            entity.updateTrackPieceAppearance()
        }
        updateMarkerPosition()
    }
    
    /// This function looks at both entities' available connection points and looks for other slide pieces
    /// they're close enough to snap to.
    func findNearestConnectionPoint (entity: Entity,
                                     connectionType: ConnectionPointType) -> (closestEntity: Entity?, distance: Float) {
        
        guard connectionType != .noPoint,
              let ourConnection = (connectionType == .inPoint) ? entity.inConnection : entity.outConnection,
              let ourVectorEntity = (connectionType == .inPoint) ? entity.inConnectionVector : entity.outConnectionVector  else {
            return (nil, Float.greatestFiniteMagnitude)
        }
        
        guard let otherEntities = entity.scene?.performQuery(connectableQuery) else { return (nil, Float.greatestFiniteMagnitude) }
        
        var closestDistance = Float.greatestFiniteMagnitude
        var closestEntity: Entity? = nil
        otherEntities.forEach() { oneEntity in
            guard oneEntity != entity && oneEntity != placePieceMarker ,
                  let theirConnection = (connectionType == .inPoint) ? oneEntity.outConnection : oneEntity.inConnection,
                  let theirVectorEntity = (connectionType == .inPoint) ? oneEntity.outConnectionVector : oneEntity.inConnectionVector else {
                return
            }
            
            let ourConnectionVector = simd_normalize(ourVectorEntity.scenePosition)
            let theirConnectionVector = simd_normalize(theirVectorEntity.scenePosition)
            
            // Make sure the orientation of the pieces is right for connection or snapping.
            let dot = simd_dot(ourConnectionVector, theirConnectionVector)
            if dot >= 0.9 && dot <= 1.1 {
                let delta = theirConnection.scenePosition - ourConnection.scenePosition
                let distance = delta.magnitude
                if distance < closestDistance {
                    closestEntity = oneEntity
                    closestDistance = distance
                }
            }
        }
        
        return (closestEntity, closestDistance)
    }
    
    /// This function turns the side lights on or off for all pieces connected to the start piece.
    func setAttachedTrackLights(to isOn: Bool) {
        guard let startPiece = startPiece else { return }
        var checkPiece: Entity? = startPiece
        while checkPiece?.connectableStateComponent?.nextPiece != nil {
            checkPiece?.setRideLights(to: isOn)
            checkPiece = checkPiece?.connectableStateComponent?.nextPiece
        }
    }
    
    /// Turns on the animated ride lights.
    func startRideLights() {
        setAttachedTrackLights(to: true)
    }
    
    /// Turns off the animated ride lights.
    func stopRideLights() {
        setAttachedTrackLights(to: false)
    }
    
    /// Starts water flowing through the ride.
    func startWaterFilling() {
        Task {
            if shouldCancelRide { return }
            try? await Task.sleep(for: .seconds(waterStartDelay))
            
            guard let startPiece = self.startPiece else { fatalError("Start piece is missing.") }
            
            var currentPiece: Entity? = startPiece
            var pieceStartTime: TimeInterval = Date.timeIntervalSinceReferenceDate
            while currentPiece != nil {
                if shouldCancelRide { return }
                try? await Task.sleep(for: .milliseconds(15))
                
                var maxFillLevel: Float?
                var duration: Float?
                currentPiece?.forEachDescendant(withComponent: RideWaterComponent.self) { entity, component in
                    maxFillLevel = component.fillLevel
                    duration = component.duration
                }
                
                guard let maxFillLevel = maxFillLevel,
                      let duration = duration else {
                    fatalError("No ride water component found.")
                }
                
                let adjustedPieceStartTime = (shouldPauseRide) ? pieceStartTime + Date.timeIntervalSinceReferenceDate - pauseStartTime
                    : pieceStartTime
                let fillLevel = Float(Date.timeIntervalSinceReferenceDate - adjustedPieceStartTime) * duration
                
                currentPiece?.setWaterLevel(level: fillLevel)
                if fillLevel >= maxFillLevel {
                    pieceStartTime = Date.timeIntervalSinceReferenceDate
                 
                    currentPiece = currentPiece?.connectableStateComponent?.nextPiece
                }
                
            }
            if shouldCancelRide { return }
            goalPiece?.setAllParticleEmittersTo(to: true, except: [fireworksParticlesName])
        }
    }
}

extension Entity {
    /// Turns ride lights on or off by setting promoted property values on Shader Graph materials.
    func setRideLights(to isOn: Bool) {
        forEachDescendant(withComponent: ModelComponent.self) { modelEntity, component in
            var modelComponent = component
            modelComponent.materials = modelComponent.materials.map {
                guard var material = $0 as? ShaderGraphMaterial else { return $0 }
                if material.parameterNames.contains(rideRunningParameterName) {
                    do {
                        let lightsOn = Bool(isOn)
                        try material.setParameter(name: rideRunningParameterName,
                                                  value: MaterialParameters.Value.bool(lightsOn))
                    } catch {
                        logger.error("Error setting ride_running material parameter: \(error.localizedDescription)")
                    }
                }
                return material
            }
            modelEntity.modelComponent = modelComponent
        }
    }
}
