/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension on Entity containing app-specific functions.
*/

import Foundation
import SwiftSplashTrackPieces
import RealityKit

public extension Entity {
    
    /// Sets visibility for animation entities for build mode and for ride mode when this piece isn't the active ride piece.
    func setUpAnimationVisibility() {
        forEachDescendant(withComponent: IdleAnimationComponent.self) { entity, component in
            // Only the start piece shows idle animations during build mode.
            entity.isEnabled = self.name == startPieceName
        }
        
        forEachDescendant(withComponent: RideAnimationComponent.self) { entity, component in
            entity.isEnabled = component.isPersistent
        }
        
        forEachDescendant(withComponent: GlowComponent.self) { entity, component in
            guard let isSelected = connectableStateComponent?.isSelected,
                  let material = connectableStateComponent?.material else { return }
            if component.isTopPiece && material == .metal {
                entity.isEnabled = true
            }
            entity.isEnabled = isSelected
        }
        forEachDescendant(withComponent: RideWaterComponent.self) { entity, component in
            entity.setWaterLevel(level: 0.0)
        }
    }
    
    /// Sets visibility for animation entities for when this piece is active during the ride.
    func setVisibilityForTrackStart() {
        forEachDescendant(withComponent: IdleAnimationComponent.self) { entity, component in
            entity.isEnabled = false
        }
        
        forEachDescendant(withComponent: RideAnimationComponent.self) { entity, component in
            entity.isEnabled = true
        }
    }
    
    func setWaterLevel(level: Float) {
        isEnabled = true
        
        func setWaterlevelOnMaterials(_ modelEntity: Entity, _ modelComponent: ModelComponent, _ level: Float) {
            modelEntity.isEnabled = level > 0
            var modelComponent = modelComponent
            modelComponent.materials = modelComponent.materials.map {
                guard var material = $0 as? ShaderGraphMaterial else { return $0 }
                if material.parameterNames.contains(waterLevelParameterName) {
                    do {
                        try material.setParameter(name: waterLevelParameterName,
                                                  value: MaterialParameters.Value.float(level))
                    } catch {
                        logger.error("Error setting ride_running material parameter: \(error.localizedDescription)")
                    }
                }
                return material
            }
            modelEntity.modelComponent = modelComponent
        }
        
        forEachDescendant(withComponent: RideWaterComponent.self) { entity, component in
            if let modelComponent = entity.modelComponent {
                setWaterlevelOnMaterials(entity, modelComponent, level)
            }
            entity.forEachDescendant(withComponent: ModelComponent.self) { modelEntity, component in
                setWaterlevelOnMaterials(modelEntity, component, level)
            }
        }
    }
    
    func hideAllIdleAndNonPersistentAnimations() {
        forEachDescendant(withComponent: IdleAnimationComponent.self) { entity, component in
            entity.isEnabled = component.playAtEndInsteadOfBeginning
            if component.playAtEndInsteadOfBeginning {
                entity.playIdleAnimations()
            }
        }
        
        forEachDescendant(withComponent: RideAnimationComponent.self) { entity, component in
            if !component.isPersistent {
                entity.isEnabled = false
            }
        }
    }
    
    /// Recursively plays all animations on this entity and all descendant entities.
    func playRideAnimations() {
        setVisibilityForTrackStart()
        var animDuration: Double = 0
        forEachDescendant(withComponent: RideAnimationComponent.self) { entity, component in
            if component.duration > animDuration {
                animDuration = component.duration / animationSpeedMultiplier
            }
            for animation in entity.availableAnimations {
                var animation = animation
                let animName = animation.name ?? "Unnamed animation"
                
                if component.alwaysAnimates {
                    animation = animation.repeat(count: Int.max)
                }
                logger.debug("Found animation \(animName) on \(entity.name)")
                
                let controller = entity.playAnimation(animation, transitionDuration: 0.0, startsPaused: false)
                rideAnimationcontrollers.append(controller)
                controller.resume()
                controller.speed = Float(animationSpeedMultiplier)
            }
        }
        Task(priority: .high) {
            await loopThroughRidePieces(animDuration: animDuration)
        }
    }
    
    private func loopThroughRidePieces(animDuration: Double) async {
        var rideStartTime: TimeInterval = Date.timeIntervalSinceReferenceDate
        var adjustedStartTime = rideStartTime
        
        var later = Date.timeIntervalSinceReferenceDate
        while later - adjustedStartTime < animDuration {
            // Keep sleep duration to less than one frame for precision (90fps = 11.11111ms).
            try? await Task.sleep(for: .milliseconds(11))
            if shouldCancelRide { return }
            later = Date.timeIntervalSinceReferenceDate
            
            if shouldPauseRide {
                handleRidePause(adjustedStartTime: &adjustedStartTime, rideStartTime: &rideStartTime)
            } else {
                if rideStartTime > 0 {
                    for controller in rideAnimationcontrollers {
                        controller.resume()
                    }
                    pauseStartTime = 0
                    rideStartTime = adjustedStartTime
                }
            }
        }

        if shouldCancelRide { return }
        if let nextPiece = self.connectableStateComponent?.nextPiece, nextPiece.name == "end" {
            handleNextEndPiece()
            handleEndPiece()
        }
        
        if shouldCancelRide { return }
        self.hideAllIdleAndNonPersistentAnimations()
        
        // Check if there's another piece after this one.
        guard let nextPiece = self.connectableStateComponent?.nextPiece else {
            return
        }
        if shouldCancelRide { return }
        // See if there's another piece connected after this one.
        logger.info("Triggering animation from \(self.name) on \(nextPiece.name) at \(Date.timestamp)")
        nextPiece.playRideAnimations()
    }
    
    private func handleEndPiece() {
        // Stop playing idle sounds.
        SoundEffect.stopLoops(for: nil)
        
        guard let endPiece = self.connectableStateComponent?.nextPiece else { fatalError("Next piece is not the end piece.") }
        
        endPiece.setRideLights(to: false)
        endPiece.setAllParticleEmittersTo(to: true, except: [waterFallParticlesName])
        Task {
            try await Task.sleep(for: .seconds(10))
            endPiece.setAllParticleEmittersTo(to: false, except: [waterFallParticlesName])
        }
    }
    
    private func handleRidePause(adjustedStartTime: inout TimeInterval, rideStartTime: inout TimeInterval ) {
        if pauseStartTime == 0 {
            pauseStartTime = Date.timeIntervalSinceReferenceDate
        }
        for controller in rideAnimationcontrollers {
            controller.pause()
        }
        adjustedStartTime = rideStartTime + Date.timeIntervalSinceReferenceDate - pauseStartTime
    }
    
    private func handleNextEndPiece() {
        SoundEffect.stopLoops(for: nil)
        SoundEffect.stopLoops(for: .fishDrop)
        SoundEffect.fishSucceed.play(on: self)
    }
 
    /// Sets all particle systems contained in this entity's hierarchy on or off.
    func setAllParticleEmittersTo(to isOn: Bool, except emittersToIgnore: [String] = [String]()) {
        self.forEachDescendant(withComponent: ParticleEmitterComponent.self) { entity, component in
            guard !emittersToIgnore.contains(entity.name) else { return }
            logger.info("Turning emitter on entity \(entity.name) to \(isOn)")
            var component = component
            component.isEmitting = isOn
            component.simulationState = (isOn) ? .play : .stop
            if isOn {
                entity.isEnabled = true
            } else {
                Task {
                    // Give the particles that have already been emitted a chance to finish.
                    try await Task.sleep(for: .seconds(4))
                    entity.isEnabled = false
                }
            }
            entity.components.set(component)
        }
    }
    
    func stopAllParticleEmittersEmitting(except emittersToIgnore: [String] = [String]()) {
        self.forEachDescendant(withComponent: ParticleEmitterComponent.self) { entity, component in
            guard !emittersToIgnore.contains(entity.name) else { return }
            logger.info("Turning off emission of particles on entity \(entity.name).")
            var component = component
            component.isEmitting = false
            entity.components.set(component)
        }
    }
    
    func stopWaterfall() {
        self.forEachDescendant(withComponent: ParticleEmitterComponent.self) { entity, component in
            var component = component
            component.isEmitting = false
            component.simulationState = .stop
            entity.components.set(component)
            entity.isEnabled = false
        }
    }
    
    func disableAllParticleEmitters(except emittersToIgnore: [String] = [String]()) {
        Task(priority: .high) {
            stopAllParticleEmittersEmitting(except: emittersToIgnore)
            try? await Task.sleep(for: .seconds(3))
            setAllParticleEmittersTo(to: false, except: emittersToIgnore)
        }
    }
    
    /// Plays idle animations so they loop.
    func playIdleAnimations() {
        forEachDescendant(withComponent: IdleAnimationComponent.self) { entity, component in
            for animation in entity.availableAnimations {
                logger.info("Found idle animation: \(String(describing: animation.name))")
                let animation = animation.repeat(count: Int.max)
                let controller = entity.playAnimation(animation, transitionDuration: 0.0, startsPaused: false)
                controller.resume()
            }
        }
    }
}
