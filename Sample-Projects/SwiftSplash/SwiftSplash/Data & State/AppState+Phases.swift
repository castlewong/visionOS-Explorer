/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that holds application state functions related to the app phase.
*/

import ARKit
import Combine
import Foundation
import RealityKit
import SwiftSplashTrackPieces
import UIKit
/// These methods expose valid state changes in the app's phase.
extension AppState {
    
    /// Call this to change app phase when you begin loading assets.
    public func finishedStartingUp() {
        phase.transition(to: .loadingAssets)
        isRideRunning = false
        rideStartTime = 0
    }
    
    /// Call this once the Reality Composer Pro project has been loaded and the template pieces created.
    public func finishedLoadingAssets() {
        phase.transition(to: .waitingToStart)
        isRideRunning = false
        rideStartTime = 0
    }
    
    /// Call this after the player has chosen the game style.
    public func startBuilding() {
        phase.transition(to: .placingStartPiece)
        isRideRunning = false
        rideStartTime = 0
        guard let startPiece = startPiece else {
            fatalError("Start piece not loaded.")
        }
        root.addChild(startPiece)
        startPiece.connectableStateComponent?.isSelected = false
        setStartPieceInitialPosition()
        trackPieceBeingEdited = nil
        clearSelection()
        updateSelection()
        startPiece.updateTrackPieceAppearance()
    }
    
    /// Call this to change the app phase after starting to drag the start piece.
    public func startedDraggingStartPiece() {
        phase.transition(to: .draggingStartPiece)

        isRideRunning = false
        rideStartTime = 0
        startAttachment?.removeFromParent()
    }
    
    /// Call this to change the app phase after the initial drag of the start piece has finished.
    public func finishedDraggingStartPiece() {
        phase.transition(to: .buildingTrack)
    }
    
    /// Starts the ride running from the start piece to the goal.
    public func startRide() {
        clearSelection()
        shouldCancelRide = false
        isRideRunning = true
        phase.transition(to: .rideRunning)
        startPiece?.setRideLights(to: true)
        goalPiece?.setRideLights(to: true)
        pauseStartTime = 0
        
        rideStartTime = Date.timeIntervalSinceReferenceDate
        if let startPiece = startPiece {
            startPiece.setUpAnimationVisibility()
            var nextPiece: Entity? = startPiece.connectableStateComponent?.nextPiece
            while nextPiece != nil {
                nextPiece?.setUpAnimationVisibility()
                nextPiece?.playIdleAnimations()
                
                if let currentPiece = nextPiece {
                    currentPiece.forEachDescendant(withComponent: RideAnimationComponent.self) { entity, component in
                        if component.alwaysAnimates {
                            for animation in entity.availableAnimations {
                                let animation = animation.repeat(count: Int.max)
                                let animName = animation.name ?? "Unnamed animation"
                                logger.debug("Found animation \(animName) on \(entity.name)")
                                let controller = entity.playAnimation(animation, transitionDuration: 0.0, startsPaused: false)
                                rideAnimationcontrollers.append(controller)
                                controller.resume()
                                controller.speed = Float(animationSpeedMultiplier)
                            }
                        }
                    }
                }
                nextPiece = nextPiece?.connectableStateComponent?.nextPiece
            }
        }

        SoundEffect.trapDoor.play(on: startPiece ?? root)
        music = .ride
        
        SoundEffect.enqueueEffectsForRide(self)
        
        if let startPiece = startPiece {
            startRideLights()
            startWaterFilling()
            calculateRideDuration()
            startPiece.playRideAnimations()
        }
        
        updateSelection()
    }
    
    /// Call this to return to the splash screen and delete the current track.
    func goBackToWaiting() {
        if phase.transition(to: .waitingToStart) {
            resetBoard()
            isRideRunning = false
            rideStartTime = 0
        }
    }
    
    /// Call this to go back to building or editing the track after calling `finishBuildingTrack()` or `startRide()`.
    func returnToBuildingTrack() {
        phase.transition(to: .buildingTrack)
    }
}
