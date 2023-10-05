/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that holds application state functions related to managing slide pieces.
*/
import ARKit
import Combine
import Foundation
import RealityKit
import SwiftUI
import SwiftSplashTrackPieces
import UIKit

extension AppState {
    
    // MARK: - Marker -
    // Places the next piece placeholder so it's connected to the specified entity.
    public func placeMarker(at entity: Entity) {
        guard let marker = placePieceMarker else { return }
        marker.isEnabled = true
        if marker.parent == nil {
            root.addChild(marker)
        }
        connect(piece: marker, to: entity)
    }
    
    public func updateMarkerPosition() {
        guard let marker = placePieceMarker,
              let lastConnectedPiece = lastConnectedPiece else { return }
        
        // Don't show the connection marker if there's no place for a piece to connect.
        if lastConnectedPiece == goalPiece {
            marker.removeFromParent()
            return
        } else if marker.parent == nil {
            root.addChild(marker)
            
        }
        
        connect(piece: marker, to: lastConnectedPiece)
    }
    
    // MARK: - Piece Templates -
    
    /// Adds an entity for a piece key.
    public func add(template: Entity, for key: TilePieceKey) {
        pieceTemplates[key] = template
    }
    
    /// Returns an entity that corresponds to a piece key.
    public func template(for key: TilePieceKey) -> Entity? {
        return pieceTemplates[key]
    }
    
    /// Makes sure two track pieces are exactly aligned, and that each has a reference to the other
    /// so the code can chain through the track pieces in order.
    func connect(piece: Entity, to otherPiece: Entity) {
        guard let lastConnectionOut = otherPiece.outConnection,
              let inConnection = piece.inConnection,
              let outConnectionVectorEntity = otherPiece.findEntity(named: SwiftSplashTrackPieces.outConnectionVectorName),
              let inConnectionVectorEntity = piece.findEntity(named: SwiftSplashTrackPieces.inConnectionVectorName),
              isDragging == false,
              isRotating == false,
              isSnapping == false else {
            return
        }
        
        // Calculate the orientation of the piece the app's connecting to.
        var lastPieceOrientation = otherPiece.sceneOrientation.normalized
        
        // Quaternions can store many rotation values in two different ways. For example, 270° around the Y
        // axis is the same as 90° around the negative Y axis. When this code encounters a rotation around a
        // negative axis, it flips it to keep everything consistent.
        if lastPieceOrientation.axis.y < 0 {
            lastPieceOrientation = simd_negate(lastPieceOrientation)
        }
        
        // If it's very close to 360°, snap to 360, which is actually 0°.
        // The ==~ operator is an "approximately equal to" comparison defined
        // in an extension in the SwiftSplashTrackPieces package. Note: this
        // is not a general purpose nearly equals operator; it uses an episilon value
        // tuned for this app's use cases.
        if lastPieceOrientation.angle ==~ (Float.pi * 2) {
            lastPieceOrientation = simd_quatf(angle: 0, axis: lastPieceOrientation.axis)
        }
        
        // Get the angle between the inverse of the out vector and the in vector.
        let outVector = simd_normalize(outConnectionVectorEntity.position)
        let invertedOutVector = simd_normalize(outVector * -1)
        let inVector = simd_normalize(inConnectionVectorEntity.position)
        
        var vectorRotationAngle = simd_quatf(from: inVector, to: invertedOutVector).normalized
        
        // When creating a quaternion from two angles, if they are 180°, the sample can't determine the axis
        // because 180° on any axis gives the same result. This tells it to use the Y axis.
        if vectorRotationAngle.angle ==~ Float.pi {
            vectorRotationAngle = simd_quatf(angle: Float.pi, axis: SIMD3<Float>.up)
        }
        
        // Combine the orientation of the last piece with the angle between the in and out vectors.
        var newRotation = (vectorRotationAngle * lastPieceOrientation).normalized
        var newRotationAngle = newRotation.angle
        
        // Snap to exactly 90° increments.
        if newRotationAngle.isNaN || newRotationAngle.isInfinite {
            newRotationAngle = 0
        }
        let divisor: Int = Int(round(newRotationAngle / pi_2))
        if divisor != 0 {
            newRotationAngle = pi_2 * Float(divisor)
        }
        
        // At exactly 180°, the sample can't determine the axis so returns NaN. When that happens,
        // tell it to use the Y axis since the piece only rotates on Y.
        if newRotation.axis.x.isNaN ||
            newRotation.axis.y.isNaN ||
            newRotation.axis.z.isNaN {
            newRotation = simd_quatf(angle: newRotationAngle, axis: SIMD3<Float>.up)
        } else {
            newRotation = simd_quatf(angle: newRotationAngle, axis: newRotation.axis)
        }
        
        // Set the new piece's rotation to the calculated amount.
        piece.sceneOrientation = newRotation
        
        // Calculate the distance between the connection points and move the piece by that much to make sure
        // the pieces are flush.
        let distanceVector = (lastConnectionOut.scenePosition - inConnection.scenePosition)
        piece.scenePosition += distanceVector
        
        if piece != placePieceMarker {
            piece.connectableStateComponent?.previousPiece = otherPiece
            otherPiece.connectableStateComponent?.nextPiece = piece
        }
    }
    
    /// Adds a specified scene to the RealityView.
    @discardableResult
    public func addEntityToScene(for key: TilePieceKey, material: MaterialType = .metal) -> Entity {
        guard let piece = pieceTemplates[key]?.clone(recursive: true) else {
            fatalError("Requested new entity of a type that doesn't exist.")
        }
        root.addChild(piece)
        piece.connectableStateComponent?.material = selectedMaterialType
        piece.updateTrackPieceAppearance()
        updateConnections()
        updateSelection()
        updatePower()
        if let lastPiece = lastConnectedPiece {
            placeMarker(at: lastPiece)
        }

        if let lastConnectedPiece = lastConnectedPiece, lastConnectedPiece != goalPiece {
            // Handle adding the piece to the end of the existing track.
            connect(piece: piece, to: lastConnectedPiece)
        } else {
            if let goalPiece = goalPiece {
                var newPosition = goalPiece.scenePosition
                newPosition.x += Float.random(in: -0.5...0.5)
                newPosition.z += Float.random(in: -0.5...0.5)
                newPosition.y += Float.random(in: -0.05...0.05)
                piece.scenePosition = newPosition
            }
        }
        updateMarkerPosition()
        updatePower()
        SoundEffect.placePiece.play(on: piece)
        piece.setUpAnimationVisibility()
        return piece
    }
    
    /// Sets a piece to use as the start point. Only one start point can exist at a time,
    /// so calling this a second time removes the previous piece.
    public func setStartPiece(_ entity: Entity) {
        startPiece?.removeFromParent()
        startPiece = entity
    }

    /// Sets a piece to use as the goal point. Only one goal point can exist at a time,
    /// so calling this a second time replaces the previous goal piece.
    public func setGoalPiece(_ entity: Entity) {
        goalPiece?.removeFromParent()
        goalPiece = entity
    }
    
    /// Adds the goal piece to the end of the track.
    public func addGoalPiece() {
        if let lastConnectedPiece = lastConnectedPiece,
           let goalPiece = goalPiece {
            root.addChild(goalPiece)
            connect(piece: goalPiece, to: lastConnectedPiece)
            goalPiece.connectableStateComponent?.material = selectedMaterialType
            goalPiece.updateTrackPieceAppearance()
            SoundEffect.placePiece.play(on: goalPiece)
            updateSelection()
            updateConnections()
        }
    }
    
    /// Removes the goal piece from the end of the track.
    public func removeGoalPiece() {
        goalPiece?.connectableStateComponent?.previousPiece?.connectableStateComponent?.nextPiece = nil
        goalPiece?.connectableStateComponent?.previousPiece = nil
        goalPiece?.connectableStateComponent?.isSelected = false
        goalPiece?.removeFromParent()
    }
    
    /// Hides the next piece position marker.
    public func hideMarkerPiece() {
        placePieceMarker?.isEnabled = false
    }
    
    /// Shows the next piece position marker.
    public func showMarkerPiece() {
        placePieceMarker?.isEnabled = true
    }
    
    /// Calculates the initial position of the start piece. On device, this uses head pose and calculates a position in front of the
    /// player. In simulator, the head pose is not available, so this hardcodes a position that's in front of the camera.
    public func setStartPieceInitialPosition() {
        
        guard let startPiece = startPiece else {
            fatalError("Attempting to place start piece, but no start piece exists.")
        }
        #if targetEnvironment(simulator)
        startPiece.position.y = 1.05
        startPiece.position.z = -1
        #else
        guard let pose = worldInfo.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
            startPiece.position.y = 1.05
            startPiece.position.z = -1
            return
        }
        let cameraMatrix = pose.originFromAnchorTransform
        let cameraTransform = Transform(matrix: cameraMatrix)
        startPiece.position = cameraTransform.translation + cameraMatrix.forward * -0.5
        #endif
    }
    
    /// Resets the state of the RealityView. Used when going back to the main menu from building or running the ride.
    public func resetBoard() {
        guard let startPiece = startPiece else {
            fatalError("Trying to reset board, but there's no start piece.")
        }
        guard let goalPiece = goalPiece else {
            fatalError("Trying to reset board, but there's no goal piece.")
        }
        goalPiece.removeFromParent()
        additionalSelectedTrackPieces.removeAll()
        trackPieceBeingEdited = nil
        
        let entities = root.scene?.performQuery(connectableQuery)
        
        entities?.forEach { entity in
            if entity != startPiece {
                while entity.parent != nil {
                    entity.removeFromParent()
                }
            }
        }
        startPiece.connectableStateComponent?.isSelected = false
        startPiece.updateTrackPieceAppearance()
        updateConnections()

    }
  
    /// Checks to make sure a connectable entity has an initialized state component. The app adds the `ConnectableStateComponent`
    /// in code for all entities with a `ConnectableComponent`so that the internal state properties don't show up in Reality Composer Pro's inspector.
    public func setupConnectable(entity: Entity) {
        // Store connection points.
        if entity.connectableStateComponent == nil {
            logger.info("Adding state component to \(entity.name).")
            var state = ConnectableStateComponent()
            state.inConnection = entity.descendants(containingSubstring: inConnectionName).first
            state.outConnection = entity.descendants(containingSubstring: outConnectionName).first
            state.entity = entity
            state.isPowered = false
            state.material = selectedMaterialType
            entity.connectableStateComponent = state
            entity.components.set(state)
            entity.updateTrackPieceAppearance()
        }
    }
    
    /// Looks around the piece for the closest other connectable piece to each of its connection points and updates the next and previous links
    /// on its state component.
    public func findClosestPieces(for entity: Entity) {
        let possibleIn = findNearestConnectionPoint(entity: entity, connectionType: .inPoint)
        if possibleIn.distance < maximumConnectionDistance {
            entity.connectableStateComponent?.previousPiece = possibleIn.closestEntity
        } else {
            entity.connectableStateComponent?.previousPiece = nil
        }
        let possibleOut = findNearestConnectionPoint(entity: entity, connectionType: .outPoint)
        if possibleOut.distance < maximumConnectionDistance {
            entity.connectableStateComponent?.nextPiece = possibleOut.closestEntity
        } else {
            entity.connectableStateComponent?.nextPiece = nil
        }
    }
}
