/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that holds application state functions related to user selection of slide pieces.
*/
import ARKit
import Combine
import Foundation
import RealityKit
import SwiftSplashTrackPieces
import UIKit

extension AppState {
    /// Call this to deselect all currently selected pieces.
    public func deleteSelectedPieces() {
        guard let entity = trackPieceBeingEdited else {
            logger.error("Delete requested, but no piece is currently being edited.")
            return
        }
        
        Task {
            SoundEffect.deletePiece.play(on: startPiece ?? root)
            if entity == startPiece {
                entity.connectableStateComponent?.isSelected = false
            } else if entity == goalPiece {
                removeGoalPiece()
            } else {
                entity.connectableStateComponent?.isSelected = false
                entity.connectableStateComponent?.previousPiece?.connectableStateComponent?.nextPiece = nil
                entity.connectableStateComponent?.nextPiece?.connectableStateComponent?.previousPiece = nil
                entity.removeFromParent()
            }
            
            for selected in additionalSelectedTrackPieces where selected.name != startPieceName {
                selected.connectableStateComponent?.isSelected = false
                selected.connectableStateComponent?.previousPiece?.connectableStateComponent?.nextPiece = nil
                selected.connectableStateComponent?.nextPiece?.connectableStateComponent?.previousPiece = nil
                selected.removeFromParent()
            }
            additionalSelectedTrackPieces.removeAll()
            try? await Task.sleep(for: .seconds(0.1))
            trackPieceBeingEdited = nil
            startPiece?.connectableStateComponent?.isSelected = false
            updateConnections()
            updatePower()
            updateMarkerPosition()
            updateSelection()
        }
    }
    
    /// Call this to add or remove a specified entity from the list of selected entities.
    public func toggleTrackPieceInSelection(entity: Entity) {
        if additionalSelectedTrackPieces.contains(entity) {
            entity.connectableStateComponent?.isSelected = false
            if let index = additionalSelectedTrackPieces.firstIndex(of: entity) {
                additionalSelectedTrackPieces.remove(at: index)
            }
        } else {
            additionalSelectedTrackPieces.append(entity)
            entity.connectableStateComponent?.isSelected = true
        }
    }
    
    /// Call this to de-select all of the pieces. Provides an option to keep the main selection (the entity with the UI above it).
    public func clearSelection(keepPrimary: Bool = false) {
        guard trackPieceBeingEdited != nil else { return }
        additionalSelectedTrackPieces.forEach { entity in
            entity.connectableStateComponent?.isSelected = false
        }
        additionalSelectedTrackPieces.removeAll()
        
        unmarkAllPieces()
        if !keepPrimary {
            trackPieceBeingEdited = nil
        }
        updateConnections()
        updatePower()
        updateSelection()
        editAttachment?.removeFromParent()
    }
    
    ///  De-selects all of the pieces.
    public func unmarkAllPieces() {
        
        let children = [Entity](root.children)
        
        for entity in children {
            guard entity.connectableStateComponent != nil else {
                continue
            }
            entity.connectableStateComponent?.isSelected = false
        }
    }
    
    /// Select all of the pieces.
    public func selectAll() {
        let children = [Entity](root.children)
        for entity in children {
            guard let entity = entity.connectableAncestor else {
                continue
            }
            if !additionalSelectedTrackPieces.contains(entity) &&
                entity != trackPieceBeingEdited &&
                entity.name != SwiftSplashTrackPieces.startPieceName {
                additionalSelectedTrackPieces.append(entity)
                entity.connectableStateComponent?.isSelected = true
            }
        }
        updateConnections()
        updatePower()
        updateSelection()
    }
    
    /// This function updates the entity visuals to reflect the selection status of the track pieces.
    public func markSelectedPieces() {
        unmarkAllPieces()
        
        root.forEachDescendant(withComponent: ConnectableComponent.self) { entity, component in
            if additionalSelectedTrackPieces.contains(entity) || entity == trackPieceBeingEdited {
                entity.connectableStateComponent?.isSelected = true
            }
        }
    }
    
    /// Selects all slide pieces that connect back to the start piece.
    public func selectConnectedPieces() {
        guard let entity = trackPieceBeingEdited else { return }
        entity.connectableStateComponent?.isSelected = true
        
        // Select all pieces in front of the selected piece.
        var piece: Entity? = entity
        while piece?.connectableStateComponent?.nextPiece != nil {
            piece = piece?.connectableStateComponent?.nextPiece
            piece?.connectableStateComponent?.isSelected = true
            if let thePiece = piece {
                additionalSelectedTrackPieces.append(thePiece)
            }
        }
        
        // Select all pieces behind the selected piece.
        piece = entity
        while piece?.connectableStateComponent?.previousPiece != nil {
            piece = piece?.connectableStateComponent?.previousPiece
            piece?.connectableStateComponent?.isSelected = true
            if let thePiece = piece {
                additionalSelectedTrackPieces.append(thePiece)
            }
        }
        updateSelection()
    }
    
    /// Returns the center point of the union of the bounding boxes for all selected track pieces. This is used as a rotation pivot point
    /// when rotating multiple pieces together.
    public var selectedTrackRotationPoint: SIMD3<Float> {
        guard var selectedExtents = trackPieceBeingEdited?.visualBounds(relativeTo: nil) else { return .zero }
        
        for entity in additionalSelectedTrackPieces {
            selectedExtents = selectedExtents.union(entity.visualBounds(relativeTo: nil))
        }
        return selectedExtents.center
    }
    
    public func entityIsInAdditionalSelectedTrackPieces(_ entity: Entity?) -> Bool {
        guard let entity = entity else { return false }
        return additionalSelectedTrackPieces.contains(entity)
    }
    
    public func setMaterialForAllSelected(_ material: MaterialType) {
        if let piece = trackPieceBeingEdited {
            piece.connectableStateComponent?.material = material
            piece.updateTrackPieceAppearance()
            
            for additionalPiece in additionalSelectedTrackPieces {
                additionalPiece.connectableStateComponent?.material = material
                additionalPiece.updateTrackPieceAppearance()
            }
        }
    }
}
