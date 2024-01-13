/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that holds application state functions related to loading slide pieces from Reality Composer Pro.
*/

import ARKit
import Combine
import Foundation
import RealityKit
import SwiftSplashTrackPieces
import UIKit

actor EntityContainer {
    var entity: Entity?
    func setEntity(_ newEntity: Entity?) {
        entity = newEntity
    }
}

struct LoadResult: Sendable {
    var entity: Entity
    var key: String
}

extension AppState {
    /// Loads a named entity and its descendants from a Reality Composer Pro scene.
    private func loadFromRCPro(named entityName: String,
                               fromSceneNamed sceneName: String,
                               scaleFactor: Float? = nil) async throws -> Entity? {
        
        var ret: Entity? = nil
        logger.info("Loading entity \(entityName) from Reality Composer Pro scene \(sceneName)")
        do {
            let scene = try await Entity(named: sceneName, in: SwiftSplashTrackPieces.bundle)
            let entityContainer = EntityContainer()
            let theRet = scene.findEntity(named: entityName)
            if let scaleFactor = scaleFactor {
                theRet?.scale = SIMD3<Float>(repeating: scaleFactor)
            }
            await entityContainer.setEntity(theRet)
            ret = await entityContainer.entity
        } catch {
            fatalError("\tEncountered fatal error: \(error.localizedDescription)")
        }
        return ret
    }
    
    /// Loads the track pieces.
    public func loadPieces() async {
        defer {
            finishedLoadingAssets()
        }
        let startTime = Date.timeIntervalSinceReferenceDate
        logger.info("Starting load from Reality Composer Pro Project.")
        finishedStartingUp()
        await withTaskGroup(of: LoadResult.self) { taskGroup in
            loadTrackPieces(taskGroup: &taskGroup)
            loadStartPiece(taskGroup: &taskGroup)
            loadGoalPiece(taskGroup: &taskGroup)
            loadPlacementMarker(taskGroup: &taskGroup)
            for await result in taskGroup {
                if let pieceKey = pieces.first(where: { $0.key.rawValue == result.key }) {
                    processLoadedTrackPiece(result: result, pieceKey: pieceKey)
                } else {
                    if result.key == startPieceName {
                        processLoadedStartPiece(result: result)
                    } else if result.key == endPieceName {
                        processLoadedGoalPiece(result: result)
                    } else if result.key == placePieceMarkerName {
                        self.placePieceMarker = result.entity
                        self.updateMarkerPosition()
                    }
                }
            }
            logger.info("Load of pieces completed. Duration: \(Date.timeIntervalSinceReferenceDate - startTime)")
        }
    }
    
    /// This function sets up the regular track pieces after load.
    private func processLoadedTrackPiece(result: LoadResult, pieceKey: Piece) {
        self.add(template: result.entity, for: pieceKey.key)
        setupConnectable(entity: result.entity)
        result.entity.components.set(HoverEffectComponent())
        result.entity.generateCollisionShapes(recursive: true)
        result.entity.setUpAnimationVisibility()
        handleTrackPieceTransparency(result.entity)
        result.entity.setWaterLevel(level: 0)
    }
    
    /// This function sets up the start piece after load.
    private func processLoadedStartPiece(result: LoadResult) {
        self.setStartPiece(result.entity)
        result.entity.setWaterLevel(level: 0)
        result.entity.setUpAnimationVisibility()
        result.entity.components.set(HoverEffectComponent())
        setStartPiece(result.entity)
        setStartPieceInitialPosition()
        setupConnectable(entity: result.entity)
        result.entity.generateCollisionShapes(recursive: true)
        result.entity.playIdleAnimations()
        handleStartPieceTransparency(result.entity)
        
        self.placeMarker(at: result.entity)
        result.entity.connectableStateComponent?.isSelected = false
        clearSelection()
        updateSelection()
    }
    
    /// This function sets up the goal piece after load.
    private func processLoadedGoalPiece(result: LoadResult) {
        self.setGoalPiece(result.entity)
        setupConnectable(entity: result.entity)
        result.entity.components.set(HoverEffectComponent())
        setGoalPiece(result.entity)
        result.entity.setUpAnimationVisibility()
        result.entity.setWaterLevel(level: 0)
        handleEndPieceTransparency(result.entity)
    }
    
    /// This function loads the regular track pieces (everything except the start and end piece and the placement marker).
    private func loadTrackPieces(taskGroup: inout TaskGroup<LoadResult>) {
        // Load the regular track pieces and ride animations.
        logger.info("Loading track pieces.")
        for piece in pieces {
            taskGroup.addTask {
                do {
                    guard let pieceEntity = try await self.loadFromRCPro(named: piece.key.rawValue,
                                                                         fromSceneNamed: piece.sceneName,
                                                                         scaleFactor: 1.5) else {
                        fatalError("Attempted to load piece entity \(piece.name) but failed.")
                    }
                    return LoadResult(entity: pieceEntity, key: piece.key.rawValue)
                } catch {
                    fatalError("Attempted to load \(piece.name) but failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// This function loads the start piece from the Reality Compoer Pro project.
    private func loadStartPiece(taskGroup: inout TaskGroup<LoadResult>) {
        taskGroup.addTask {
            var result: Entity? = nil
            do {
                logger.info("Loading start piece.")
                if let entity = try await self.loadFromRCPro(named: startPieceName,
                                                             fromSceneNamed: SwiftSplashTrackPieces.startPieceSceneName,
                                                             scaleFactor: 1.5) {
                    result = entity
                }
            } catch {
                fatalError("Attempted to load start entity but failed: \(error.localizedDescription)")
            }
            guard let result = result else {
                fatalError("Loaded start piece is nil")
            }
            return LoadResult(entity: result, key: startPieceName)
        }
    }
    
    /// This function loads the goal piece from the Reality Composer Pro project.
    private func loadGoalPiece(taskGroup: inout TaskGroup<LoadResult>) {
        taskGroup.addTask {
            var result: Entity? = nil
            do {
                logger.info("Loading goal piece.")
                // Load the end piece.
                if let goalPiece = try await self.loadFromRCPro(named: endPieceName, fromSceneNamed: endPieceSceneName, scaleFactor: 1.5) {
                    result = goalPiece
                }
            } catch {
                fatalError("Attempted to load goal entity but failed: \(error.localizedDescription)")
            }
            guard let result = result else {
                fatalError("Loaded start piece is nil.")
            }
            return LoadResult(entity: result, key: endPieceName)
        }
    }
    
    private func loadPlacementMarker(taskGroup: inout TaskGroup<LoadResult>) {
        taskGroup.addTask {
            var result: Entity?
            do {
                logger.info("Loading next piece placement marker.")
                // Load the marker that shows where the next piece will go.
                if let placementMarker = try await self.loadFromRCPro(named: placePieceMarkerName, fromSceneNamed: placePieceMarkerSceneName) {
                    result = placementMarker
                }
            } catch {
                fatalError("Attempted to load piece placement marker entity but failed: \(error.localizedDescription)")
            }
            guard let result = result else {
                fatalError("Loaded start piece is nil")
            }
            return LoadResult(entity: result, key: placePieceMarkerName)
        }
    }
}
