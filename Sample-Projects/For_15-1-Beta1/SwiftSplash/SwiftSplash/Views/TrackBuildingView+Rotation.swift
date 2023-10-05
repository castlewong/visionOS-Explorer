/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension on the track-building view that contains functions related to rotating slide pieces.
*/

import SwiftUI
import RealityKit
import SwiftSplashTrackPieces
import simd

struct RotateSnapInfo: Sendable {
    let entity: Entity
    let startDegrees: Double
    let destinationDegrees: Double
    let startTime: TimeInterval
}

extension TrackBuildingView {
    
    /// Creates a parent entity for rotation and place it at the correct pivot point based on center
    /// of the combined bounding boxes of the selected pieces.
    @MainActor
    private func createRotationParent(for entity: Entity) {
        
        rotationParent = Entity()
        rotationParent?.name = rotatingParentNodeName
        if let rotationParent = rotationParent {
            appState.setupConnectable(entity: rotationParent)
        }

        if let rotationParent = rotationParent {
            appState.root.addChild(rotationParent)
        }
        rotationParent?.scenePosition = appState.selectedTrackRotationPoint
        
        if let trackPieceBeingEdited = appState.trackPieceBeingEdited {
            trackPieceBeingEdited.setParent(rotationParent, preservingWorldTransform: true)
        }
        for selectedPiece in appState.additionalSelectedTrackPieces {
            if let rotationParent = rotationParent {
                selectedPiece.setParent(rotationParent, preservingWorldTransform: true)
            }
        }
        entity.setParent(rotationParent, preservingWorldTransform: true)
        appState.updateSelection()
    }
    
    /// The logic to handle the input fom a rotation gesture.
    @MainActor
    func handleRotationChanged(_ value: EntityTargetValue<RotateGesture.Value>, isEnded: Bool = false) {
        guard !(isEnded == true && isSnapping == true) else { return }
        guard appState.phase == .buildingTrack || appState.phase == .placingStartPiece || appState.phase == .draggingStartPiece  else {
            logger.info("Wrong phase for rotation, returning.")
            isRotating = false
            return
        }
        guard let entity = value.entity.connectableAncestor else {
            logger.debug("Could not find a connectable component on gesture entity or its ancestors.")
            isRotating = false
            return
        }
        
        isRotating = true
        
        if appState.phase == .placingStartPiece {
            appState.startedDraggingStartPiece()
        }
        
        // If somebody rotates a piece that's not selected, clear the selection and select the dragged piece.
        if  rotatedEntity == nil {
            rotatedEntity = entity
            if appState.trackPieceBeingEdited == nil ||
                (appState.trackPieceBeingEdited != rotatedEntity && !appState.entityIsInAdditionalSelectedTrackPieces(rotatedEntity)) {
                appState.clearSelection()
                appState.trackPieceBeingEdited = rotatedEntity
                appState.trackPieceBeingEdited?.connectableStateComponent?.isSelected = true
            }
        }
        
        appState.editAttachment?.removeFromParent()

        // If there's only one selected track piece, rotate just that piece.
        if appState.additionalSelectedTrackPieces.isEmpty {
            if appState.trackPieceBeingEdited == nil {
                rotationParent = entity
            } else {
                rotationParent = appState.trackPieceBeingEdited
            }
        } else {
            // If there are multiple selected tracks, create a common parent to rotate.
            if rotationParent == nil {
               createRotationParent(for: entity)
            }
        }
        guard let rotationParent = rotationParent else {
            fatalError("App attempted to rotate object without rotation entity.")
        }
        setRotation(entity: rotationParent, radians: -value.gestureValue.rotation.radians, snap: isEnded)
        appState.updatePower()
        appState.updateConnections()
        appState.updateMarkerPosition()
    }
    
    /// Sets the rotation value for an entity being manipulated using the 3D rotation gesture.
    func setRotation(entity: Entity, radians: Double, snap: Bool = false) {
        // Increase rotation speed.
#if targetEnvironment(simulator)
        let radians = radians * 3
#else
        let radians = radians * 8
#endif
        // Retrieve the rotation value from when the gesture started.
        if let startAngleRadians = entity.connectableStateComponent?.startRotation {
            
            let startAngleDegrees = Angle(radians: startAngleRadians).degrees
            let angleDegrees = Angle(radians: radians).degrees + startAngleDegrees
            let angleRadians = Angle(degrees: angleDegrees).radians
            
            // Determine if there is another slide piece close enough to snap to, and
            // implement the snapping behavior.
            if snap && !isSnapping {
                
                var destinationDegrees = angleDegrees + 45
                destinationDegrees = Double(Int(floor(destinationDegrees / 90)) * 90)
                let info = RotateSnapInfo(entity: entity, startDegrees: angleDegrees,
                                          destinationDegrees: destinationDegrees,
                                          startTime: Date.timeIntervalSinceReferenceDate)
                
                // Each pass through the loop moves the dragged piece closer to the piece it's snapping to.
                Task(priority: .high) { @MainActor in
                    defer {
                        isRotating = false
                    }
                    
                    try? await loopForSnap(info: info, entity: entity, radians: radians)

                    Task {
                        self.rotationParent?.removeFromParent()
                        self.rotationParent = nil
                        rotatedEntity = nil
                        if let attachmentPoint = appState.trackPieceBeingEdited?.uiAnchor,
                           let editAttachment = appState.editAttachment {
                            attachmentPoint.addChild(editAttachment)
                            
                        }
                        try await Task.sleep(for: .seconds(0.25))
                        isRotating = false
                    }
                    appState.updateMarkerPosition()
                }
                return
            }
            entity.sceneOrientation = simd_quatf(angle: Float(angleRadians), axis: SIMD3<Float>.up).normalized
        }
    }
    @MainActor
    private func loopForSnap(info: RotateSnapInfo,
                             entity: Entity,
                             radians: Double) async throws {
        var done = false
        while !done {
            try await Task.sleep(for: .milliseconds(11))
            let degreesToAdd = (Date.timeIntervalSinceReferenceDate - info.startTime) * (rotateSnapTime * 45)
            var newRotationDegrees = info.startDegrees + degreesToAdd
            if newRotationDegrees >= info.destinationDegrees {
                newRotationDegrees = info.destinationDegrees
                done = true
            }
            let newRotationRadians = Angle(degrees: newRotationDegrees).radians
            info.entity.sceneOrientation = simd_quatf(angle: Float(newRotationRadians), axis: SIMD3<Float>.up).normalized
        }
        
        if  self.rotationParent?.name != rotatingParentNodeName {
            self.rotationParent = nil
            isRotating = false
            return
        }
        
        if let parent = self.rotationParent {
            // Calling setParent on an child while iterating the children invalidates the iterator
            // so create a new array with the child entities and iterate that instead.
            let children = [Entity](parent.children)
            for child in children {
                child.setParent(appState.root, preservingWorldTransform: true)
                child.connectableStateComponent?.startRotation = 0
            }
        }
    }
}
