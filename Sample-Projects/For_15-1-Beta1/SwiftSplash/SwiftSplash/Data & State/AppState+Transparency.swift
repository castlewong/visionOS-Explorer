/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that holds application state functions related to manually sorting transparent objects to ensure correct rendering.
*/

import ARKit
import Combine
import Foundation
import RealityKit
import SwiftSplashTrackPieces
import UIKit

public extension AppState {
    
    /// Utility function that adds a model sort group component to an entity.
    fileprivate func setEntityDrawOrder(_ entity: Entity, _ sortOrder: Int32, _ sortGroup: ModelSortGroup) {
        entity.forEachDescendant(withComponent: ModelComponent.self) { modelEntity, model in
            logger.info("Setting sort order of \(sortOrder) of \(entity.name), child entity: \(modelEntity.name)")
            let component = ModelSortGroupComponent(group: sortGroup, order: sortOrder)
            modelEntity.components.set(component)
        }
    }
    
    /// Manually specifies sort ordering for the transparent start piece meshes.
    func handleStartPieceTransparency(_ startPiece: Entity) {
        let group = ModelSortGroup()
        
        // Opaque fish parts.
        if let entity = startPiece.findEntity(named: fishIdleAnimModelName) {
            setEntityDrawOrder(entity, 1, group)
        }
        if let entity = startPiece.findEntity(named: fishRideAnimModelName) {
            setEntityDrawOrder(entity, 2, group)
        }
        
        // Transparent fish parts.
        if let entity = startPiece.findEntity(named: fishGlassIdleAnimModelName) {
            setEntityDrawOrder(entity, 3, group)
        }
        if let entity = startPiece.findEntity(named: fishGlassRideAnimModelName) {
            setEntityDrawOrder(entity, 4, group)
        }
        
        // Water.
        if let entity = startPiece.findEntity(named: sortOrderWaterName) {
            setEntityDrawOrder(entity, 5, group)
        }
        
        // Glass globe.
        if let entity = startPiece.findEntity(named: sortOrderGlassGlobeName) {
            setEntityDrawOrder(entity, 6, group)
        }
        
        // Selection glow.
        if let entity = startPiece.findEntity(named: startGlowName) {
            setEntityDrawOrder(entity, 7, group)
        }
    }
    
    /// Manually specifies sort ordering for transparent track pieces.
    func handleTrackPieceTransparency(_ trackPiece: Entity) {
        let group = ModelSortGroup()
    
        // Find opaque fish parts and set sort order to 1.
        trackPiece.forEachDescendant(withSuffix: sortOrderFishGlassSuffix) { entity in
            setEntityDrawOrder(entity, 1, group)
        }
        
        // Find transparent fish parts and set sort order to 2
        trackPiece.forEachDescendant(withSuffix: sortOrderFishSuffix) { entity in
            setEntityDrawOrder(entity, 2, group)
        }
        
        // Find water parts and set sort order to 3.
        trackPiece.forEachDescendant(withSuffix: sortOrderWaterSuffix) { entity in
            setEntityDrawOrder(entity, 3, group)
        }
        
        // Find the glass top piece and set sort order to 4.
        trackPiece.forEachDescendant(withSuffix: sortOrderTrackTopsuffix) { entity in
            setEntityDrawOrder(entity, 4, group)
        }
        
        // Find the top glow piece and set sort order to 5.
        trackPiece.forEachDescendant(withSuffix: sortOrderTrackGlowSuffix) { entity in
            setEntityDrawOrder(entity, 5, group)
        }
    }
    
    /// Manually specifies sort ordering for the transparent goal piece meshes.
    func handleEndPieceTransparency(_ endPiece: Entity) {
        let group = ModelSortGroup()
        
        if let entity = endPiece.findEntity(named: sortOrderEndWaterName) {
            setEntityDrawOrder(entity, 1, group)
        }
        if let entity = endPiece.findEntity(named: sortOrderEndSlideName) {
            let component = ModelSortGroupComponent(group: group, order: 2)
            entity.components.set(component)
        }
        if let entity = endPiece.findEntity(named: sortOrderEndSlideTopName) {
            setEntityDrawOrder(entity, 3, group)
        }
    }
}
