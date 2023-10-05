/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Displays the RealityKit content in an immersive space.
*/

import SwiftUI
import RealityKit
import SwiftSplashTrackPieces
import simd
/// The main immersive space for building the ride.
struct TrackBuildingView: View {
    @Environment(AppState.self) var appState
    @Environment(\.dismiss) internal var dismiss
    @Environment(\.openWindow) internal var openWindow
    
    @State internal var lastTouchDownTime: TimeInterval = 0
    
    @State internal var draggedEntity: Entity? = nil
    @State internal var rotatedEntity: Entity? = nil
    
    @State internal var shouldSingleTap = false
    @State internal var dragStartTime: TimeInterval?
    @State internal var subscriptions = [EventSubscription]()
    @State internal var rotationParent: Entity? = nil
    
    let doubleTapTolerance = 0.25
    static let editUIQuery = EntityQuery(where: .has(EditUILocationMarkerComponent.self))
    static let connectableQuery = EntityQuery(where: .has(ConnectableComponent.self))
    
    enum AttachmentIDs: Int {
        case editMenu = 100
        case startCard = 101
    }
    
    var body: some View {
        RealityView { content, attachments in
            content.add(appState.root)
            
            if let editMenu = attachments.entity(for: AttachmentIDs.editMenu) {
                appState.editAttachment = editMenu
                if let piece = appState.trackPieceBeingEdited {
                    piece.uiAnchor?.addChild(editMenu)
                } else {
                    editMenu.removeFromParent()
                }
            }
            if let startMenu = attachments.entity(for: AttachmentIDs.startCard) {
                appState.startAttachment = startMenu
                if let startPiece = appState.startPiece {
                    startPiece.instructionsMarker?.addChild(startMenu)
                }
            }
        } attachments: {
            Attachment(id: AttachmentIDs.editMenu) {
                EditTrackPieceView()
            }
            Attachment(id: AttachmentIDs.startCard) {
                PlaceStartPieceView()
            }
        }
        .gesture(DragGesture(minimumDistance: 1)
            .targetedToAnyEntity()
            .onChanged { value in
                guard appState.phase == .buildingTrack || appState.phase == .placingStartPiece
                        || appState.phase == .draggingStartPiece else { return }
                handleDrag(value, ended: false)
            }
            .onEnded { value in
                guard appState.phase == .buildingTrack || appState.phase == .placingStartPiece
                        || appState.phase == .draggingStartPiece else { return }
                handleDrag(value, ended: true)
            })
        .simultaneousGesture(
            RotateGesture()
                .targetedToAnyEntity()
                .onChanged({ value in
                    guard appState.phase == .buildingTrack || appState.phase == .placingStartPiece
                            || appState.phase == .draggingStartPiece else { return }
                    handleRotationChanged(value)
                })
                .onEnded({ value in
                    guard appState.phase == .buildingTrack || appState.phase == .placingStartPiece
                            || appState.phase == .draggingStartPiece else { return }
                    handleRotationChanged(value, isEnded: true)
                })
        )
        .simultaneousGesture(
            TapGesture(count: 2)
                .targetedToAnyEntity()
                .onEnded({ value in
                    guard appState.phase == .buildingTrack else { return }
                    shouldSingleTap = false
                    guard let entity = value.entity.connectableAncestor else {
                        logger.error("Double tap entity not found.")
                        return
                    }
                    if appState.trackPieceBeingEdited == nil {
                        appState.trackPieceBeingEdited = entity
                    } else {
                        appState.toggleTrackPieceInSelection(entity: entity)
                    }
                    appState.updateSelection()
                })
        )
        .simultaneousGesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded({ value in
                    guard appState.phase == .buildingTrack else { return }
                    Task {
                        defer {
                            appState.updateVisuals()
                        }
                        
                        shouldSingleTap = true
                        try? await Task.sleep(for: .seconds(doubleTapTolerance))
                        if shouldSingleTap {
                            guard let entity = value.entity.connectableAncestor else {
                                logger.error("Tap gesture provided no entity.")
                                return
                            }
                            guard entity != appState.placePieceMarker else {
                                logger.info("Tap on placement marker. This piece doesn't support edit mode.")
                                return
                            }
                            
                            SoundEffect.selectPiece.play(on: entity)
                            
                            if appState.trackPieceBeingEdited == entity {
                                appState.trackPieceBeingEdited = nil
                                appState.clearSelection()
                                entity.connectableStateComponent?.isSelected = false
                                
                                if let editMenu = appState.editAttachment, editMenu.parent != nil {
                                    editMenu.removeFromParent()
                                }
                                appState.updateConnections()
                                appState.updateSelection()
                            } else {
                                Task {
                                    appState.trackPieceBeingEdited = entity.connectableAncestor
                                    appState.trackPieceBeingEdited?.connectableStateComponent?.isSelected = true
                                    appState.clearSelection(keepPrimary: true)
                                    if let editMenu = appState.editAttachment {
                                        if editMenu.parent != nil {
                                            editMenu.removeFromParent()
                                        }
                                        
                                        entity.uiAnchor?.addChild(editMenu)
                                    }
                                }
                            }
                            appState.updateConnections()
                            appState.updateSelection()
                        }
                        shouldSingleTap = false
                    }
                })
        )
        .onChange(of: appState.phase.isImmersed) { _, showMRView in
            if !showMRView {
                dismiss()
            }
        }
    }
}
    
#Preview {
    TrackBuildingView()
        .environment(AppState())
}
