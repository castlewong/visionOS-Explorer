/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that holds application state functions related to running the water ride.
*/

import ARKit
import Combine
import Foundation
import RealityKit
import SwiftSplashTrackPieces
import UIKit

/// These methods expose valid state changes in the app's phase.
extension AppState {
    
    /// Calculates the duration of the built ride by summing up the individual slide piece durations.
    public func calculateRideDuration() {
        guard let startPiece = startPiece else { fatalError("No start piece found.") }
        var nextPiece: Entity? = startPiece
        var duration: TimeInterval = 0
        while nextPiece != nil {
            // Some pieces have more than one ride animation. Use the longest one to calculate duration.
            var longestAnimation: TimeInterval = 0
            nextPiece?.forEachDescendant(withComponent: RideAnimationComponent.self) { entity, component in
                longestAnimation = max(component.duration, longestAnimation)
            }
            duration += longestAnimation
            nextPiece = nextPiece?.connectableStateComponent?.nextPiece
        }
        // Remove the part of the animation after the goal post.
        rideDuration = duration / animationSpeedMultiplier + 1.0
    }
    
    /// Call this when returning to build mode to reset the animations and hide the moving fish and water.
    public func resetRideAnimations() {
        guard let startPiece = startPiece else { fatalError("No start piece found.") }
        
        for controller in rideAnimationcontrollers {
            controller.pause()
            controller.time = 0
        }
        rideAnimationcontrollers.removeAll()
        
        var currentPiece: Entity? = goalPiece
        Task {
            try await Task.sleep(for: .seconds(10))
            while currentPiece != nil {
                currentPiece?.setRideLights(to: false)
                currentPiece = currentPiece?.connectableStateComponent?.previousPiece
            }
        }
        
        var nextPiece: Entity? = startPiece
        while nextPiece != nil {
            if let nextpiece = nextPiece {
                nextpiece.setWaterLevel(level: 0)
                nextpiece.setAllParticleEmittersTo(to: false)
                nextpiece.forEachDescendant(withComponent: RideAnimationComponent.self) { entity, component in
                    entity.isEnabled = component.isPersistent
                    
                    for animation in entity.availableAnimations {
                        let animation = animation.repeat(count: Int.max)
                        let controller = entity.playAnimation(animation, transitionDuration: 0.0, startsPaused: true)
                        controller.time = component.timecodeWhenNotPlaying
                    }
                }
            }
            nextPiece?.setUpAnimationVisibility()
            nextPiece = nextPiece?.connectableStateComponent?.nextPiece
        }
        
    }
}
