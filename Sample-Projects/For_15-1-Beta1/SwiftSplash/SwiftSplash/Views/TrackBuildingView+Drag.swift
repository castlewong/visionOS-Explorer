/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension on the track-building view that contains functions related to dragging slide pieces.
*/

import SwiftUI
import RealityKit
import SwiftSplashTrackPieces
import simd

extension TrackBuildingView {
    
    /// The logic to handle the `.onChanged` event from a rotation gesture.
    @MainActor
    func handleDrag(_ value: EntityTargetValue<DragGesture.Value>, ended: Bool = false) {
        // On a rotate gesture, the drag gesture can also be called. Only one of the two
        // gestures will work at a time, so if there's a rotation in progress, return without
        // handling the drag.
        guard !isRotating else { return }
        
        defer {
            if ended {
                handleDragEnd(value)
                showEditUI()
                isDragging = false
            }
        }

        appState.editAttachment?.removeFromParent()
        
        lastTouchDownTime = Date.timeIntervalSinceReferenceDate
        // Gestures might hit a child entity. This traverses up to the connectable ancestor, if needed.
        let tappedEntity = value.entity
        if let entity = tappedEntity.connectableAncestor {
            if appState.phase == .placingStartPiece {
                appState.startedDraggingStartPiece()
            }
            
            // Disallow dragging the end-of-track marker.
            if entity.name == SwiftSplashTrackPieces.placePieceMarkerName {
                return
            }
            draggedEntity = entity
            isDragging = true
            
            if appState.trackPieceBeingEdited != entity && !appState.additionalSelectedTrackPieces.contains(entity) {
                selectDraggedPiece(draggedEntity: draggedEntity)
            }
            
            if appState.trackPieceBeingEdited != nil && entity != appState.trackPieceBeingEdited
                && !appState.additionalSelectedTrackPieces.contains(entity) {
                appState.clearSelection(keepPrimary: false)
            }
            
            var allDragged = handleEntityStateUpdates(for: entity)
            
            draggedPiece = entity
            
            let translation3D = value.convert(value.gestureValue.translation3D, from: .local, to: .scene)
            
            let offset = SIMD3<Float>(x: Float(translation3D.x),
                                      y: Float(translation3D.y),
                                      z: Float(translation3D.z))
            
            updateDraggedPositions(&allDragged, offset: offset)
            
            // Handle snapping.
            if ended {
                let snapInfo = DragSnapInfo(entity: entity,
                                        otherSelectedEntities: Array(allDragged))
                guard let others = entity.scene?.performQuery(Self.connectableQuery) else {
                    logger.info("No entities to snap to, returning.")
                    isDragging = false
                    return
                }
                handleSnap(snapInfo,
                           allConnectableEntities: others)
                isDragging = false
            }
            if appState.phase != .draggingStartPiece {
                updateDraggedPieceConnections(entity: entity)
            }
        }
    }
    
    /// At the end of the drag, this function resets the dragged entities' state components.
    @MainActor
    func handleDragEnd(_ value: EntityTargetValue<DragGesture.Value>) {
        defer {
            isDragging = false
            draggedEntity = nil
            dragStartTime = nil
            appState.updateConnections()
            appState.updateSelection()
        }
        
        if appState.phase == .draggingStartPiece {
            openWindow(id: "SwiftSplash")
            appState.finishedDraggingStartPiece()
        }
        
        func resetPiece(_ entity: Entity) {
            if var state = entity.connectableStateComponent {
                state.nextPiece = nil
                state.previousPiece = nil
                state.lastMoved = NSDate.timeIntervalSinceReferenceDate
                state.dragOffset = SIMD3<Float>.zero
                state.dragStart = nil
                entity.connectableStateComponent = state
                appState.findClosestPieces(for: entity)
                SoundEffect.placePiece.play(on: entity)
                if entity == appState.trackPieceBeingEdited {
                    if let attachmentPoint = appState.trackPieceBeingEdited?.uiAnchor,
                       let editAttachment = appState.editAttachment {
                        attachmentPoint.addChild(editAttachment)
                    }
                }
            }
        }
        if let dragged = appState.trackPieceBeingEdited {
            resetPiece(dragged)
        }
        for dragged in appState.additionalSelectedTrackPieces {
            resetPiece(dragged)
        }
        
        if let attachmentPoint = appState.trackPieceBeingEdited?.uiAnchor,
           let editAttachment = appState.editAttachment {
            attachmentPoint.addChild(editAttachment)
        }

    }
    
    /// The selected piece has an attachment used to edit it. This shows it after the drag is finished.
    @MainActor
    private func showEditUI() {
        if let attachmentPoint = appState.trackPieceBeingEdited?.uiAnchor,
           let editAttachment = appState.editAttachment {
            attachmentPoint.addChild(editAttachment)
        }
    }
    
    /// Updates a dragged entity's state component based on the results of the drag.
    @MainActor
    private func handleEntityStateUpdates(for entity: Entity) -> Set<Entity> {
        defer {
            isDragging = false
        }
        var allDragged = Set<Entity>(appState.additionalSelectedTrackPieces)
        allDragged.insert(entity)
        if entity != appState.trackPieceBeingEdited,
            let selected = appState.trackPieceBeingEdited {
            allDragged.insert(selected)
        }
        guard var state = entity.connectableStateComponent else { return Set<Entity>() }
        if state.dragStart == nil {
            state.lastMoved = NSDate.timeIntervalSinceReferenceDate
            state.dragStart = entity.scenePosition
            SoundEffect.selectPiece.play(on: entity)
            
            for piece in allDragged {
                piece.connectableStateComponent?.dragStart = piece.scenePosition
                piece.connectableStateComponent?.dragOffset = .zero
            }
            entity.connectableStateComponent = state
        }

        return allDragged
    }
    
    /// As slide pieces are dragged, their connection status to other pieces changes. This
    /// determines if the piece, in its current location, is connected to another piece,
    /// and updates the pieces state component if it is.
    @MainActor
    private func updateDraggedPieceConnections(entity: Entity) {
        appState.findClosestPieces(for: entity)
        if let next = entity.connectableStateComponent?.nextPiece {
            appState.findClosestPieces(for: next)
        }
        if let previous = entity.connectableStateComponent?.previousPiece {
            appState.findClosestPieces(for: previous    )
        }
    }
    
    @MainActor
    private func selectDraggedPiece(draggedEntity: Entity?) {
        appState.clearSelection()
        appState.trackPieceBeingEdited = draggedEntity
        draggedEntity?.connectableStateComponent?.isSelected = true
        appState.updateConnections()
        appState.updateSelection()
    }
    
    /// If multiple pieces are dragged at once, this function applies the drag offset to all of them.
    @MainActor
    private func updateDraggedPositions(_ allDragged: inout Set<Entity>, offset: SIMD3<Float>) {
        for oneDragged in allDragged {
            oneDragged.connectableStateComponent?.dragOffset = offset
            guard let oneState = oneDragged.connectableStateComponent,
                  let dragStart = oneState.dragStart else {
                continue
            }
            if oneDragged.parent?.name != rotatingParentNodeName {
                oneDragged.scenePosition = dragStart + oneState.dragOffset
            }
        }
        appState.updateMarkerPosition()
    }
}
