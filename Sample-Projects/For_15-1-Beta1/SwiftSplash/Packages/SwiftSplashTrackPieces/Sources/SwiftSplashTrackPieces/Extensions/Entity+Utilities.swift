/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension on Entity containing convenience and utility functions.
*/

import Foundation
import OSLog
import RealityKit

/// Convenience methods for `Entity`.
public extension Entity {
    
    /// Returns an array containing all descendants with a name that includes a specified substring.
    func descendants(containingSubstring substring: String) -> [Entity] {
        var childTransforms = children.filter { child in
            return child.name.contains(substring)
        }
        var myTransforms = [Entity]()
        for child in children {
            childTransforms.append(contentsOf: child.descendants(containingSubstring: substring))
        }
        myTransforms.append(contentsOf: childTransforms)
        return myTransforms
    }
    
    /// Recursive search of children returning any descendants with a specific component and calling a closure with them.
    func forEachDescendant(containingSubstring substring: String, _ closure: (Entity) -> Void) {
        for child in children {
            if child.name.contains(substring) {
                closure(child)
            }
            child.forEachDescendant(containingSubstring: substring, closure)
        }
    }
    
    /// Recursive search of children with a name that has a specified suffix.
    func forEachDescendant(withSuffix suffix: String, _ closure: (Entity) -> Void) {
        for child in children {
            if child.name.hasSuffix(suffix) {
                closure(child)
            }
            child.forEachDescendant(withSuffix: suffix, closure)
        }
    }
    
    /// Returns the position of the entity specified in the app's coordinate system. On
    /// iOS and macOS, which don't have a device native coordinate system, scene
    /// space is often referred to as "world space".
    var scenePosition: SIMD3<Float> {
        get { position(relativeTo: nil) }
        set { setPosition(newValue, relativeTo: nil) }
    }
    
    /// Returns the orientation of the entity specified in the app's coordinate system. On
    /// iOS and macOS, which don't have a device native coordinate system, scene
    /// space is often referred to as "world space".
    var sceneOrientation: simd_quatf {
        get { orientation(relativeTo: nil) }
        set { setOrientation(newValue, relativeTo: nil) }
    }
}

/// Entity extension holding convenience accessors and mutators for the components
/// this system uses. Components are stored in the `components` dictionary using the
/// component class (`.self`) as the key. This adds calculated properties to allow setting
/// and getting these components.
public extension Entity {
    /// Property for getting or setting an entity's `ConnectableComponent`.
    var connectableComponent: ConnectableComponent? {
        get { components[ConnectableComponent.self] }
        set { components[ConnectableComponent.self] = newValue }
    }
    
    /// Property for getting or setting an entity's `ConnectableStateComponent`.
    var connectableStateComponent: ConnectableStateComponent? {
        get { components[ConnectableStateComponent.self] }
        set { components[ConnectableStateComponent.self] = newValue }
    }

    /// Property for getting or setting an entity's `ModelComponent`.
    var modelComponent: ModelComponent? {
        get { components[ModelComponent.self] }
        set { components[ModelComponent.self] = newValue }
    }
    
    /// Property for getting or setting an entity's `RideAnimationComponent`.
    var rideAnimationComponent: RideAnimationComponent? {
        get { components[RideAnimationComponent.self] }
        set { components[RideAnimationComponent.self] = newValue }
    }
    
    /// Property for getting or setting an entity's `IdleAnimationComponent`.
    var idleAnimationComponent: IdleAnimationComponent? {
        get { components[IdleAnimationComponent.self] }
        set { components[IdleAnimationComponent.self] = newValue }
    }
    
    /// Property for getting or setting an entity's `GlowComponent`.
    var glowComponent: GlowComponent? {
        get { components[GlowComponent.self] }
        set { components[GlowComponent.self] = newValue }
    }
}

// MARK: - Connected Power System -
public extension Entity {
    
    /// Marks a track piece as powered, indicating it's connected back to the start piece.
    func turnOnPower() {
        setPower(isPowered: true)
    }
    
    /// Marks a track piece as unpowered, indicating it isn't connected back to the start piece.
    func turnOffPower() {
        setPower(isPowered: false)
    }
    
    /// Updates dynamic Shader Graph materials based on the current state of the track piece and
    /// also hides and shows prims that are state-dependent, such as the slide top pieces, which are
    /// only visible when the metal material is selected.
    func updateTrackPieceAppearance() {
        forEachDescendant(withComponent: ModelComponent.self) { modelEntity, component in
            var modelComponent = component
            modelComponent.materials = modelComponent.materials.map {
                guard var material = $0 as? ShaderGraphMaterial else { return $0 }
                if material.parameterNames.contains(materialParameterName) {
                    do {
                        let pieceMaterial = Int32( connectableStateComponent?.material.rawValue ?? MaterialType.metal.rawValue)
                        let materialIndex = MaterialParameters.Value.int(pieceMaterial)
                        try material.setParameter(name: materialParameterName,
                                                  value: materialIndex)
                    } catch {
                        os_log(.error, "Error setting track material parameter: %s", error.localizedDescription)
                    }
                }
                return material
            }
            modelEntity.modelComponent = modelComponent
        }

        // Hide or show the top part of the slide depending on the material.
        for entity in self.descendants(containingSubstring: SwiftSplashTrackPieces.slideTopName) {
            if let state = connectableStateComponent {
                if state.material == .metal {
                    if entity.name.hasSuffix("_glow") {
                        entity.isEnabled = state.isSelected
                    } else {
                        entity.isEnabled = true
                    }
                } else {
                    entity.isEnabled = false
                }
                
            }
        }
        
        self.forEachDescendant(withComponent: GlowComponent.self) { entity, component in
            guard let state = connectableStateComponent else { return }
            entity.isEnabled = state.isSelected
        }
    }
    
    func setPower(isPowered: Bool, isChild: Bool = false) {
        for child in children {
            child.setPower(isPowered: isPowered, isChild: true)
        }
        
        if !isChild {
            if var stateComponent = self.connectableStateComponent {
                // Because it's set to the same value it already is, no need to do anything.
                if isPowered == stateComponent.isPowered { return }
                
                // Value changes, so store it in the powered component.
                stateComponent.isPowered = isPowered
                self.connectableStateComponent = stateComponent
            }
        }
        
        if var modelComponent = self.modelComponent {
            modelComponent.materials = modelComponent.materials.map {
                guard var material = $0 as? ShaderGraphMaterial else { return $0 }
                if material.parameterNames.contains(poweredMaterialParameterName) {
                    do {
                        try material.setParameter(name: poweredMaterialParameterName, value: .float(isPowered ? 1.0 : 0.0))
                    } catch {
                        os_log("Error setting Powered parameter: \(error.localizedDescription)")
                    }
                }
                return material
            }
            self.modelComponent = modelComponent
        }
    }
    
    /// An entity that marks where this piece connects to the previous piece.
    var inConnection: Entity? {
        findEntity(named: SwiftSplashTrackPieces.inConnectionName)
    }
    
    /// An entity that marks where this piece connects to the next piece.
    var outConnection: Entity? {
        findEntity(named: SwiftSplashTrackPieces.outConnectionName)
    }
    
    /// A vector that indicates the direction of the piece's in connection.
    var inConnectionVector: Entity? {
        findEntity(named: SwiftSplashTrackPieces.inConnectionVectorName)
    }
    
    /// A vector that indicates the direction of the piece's out connection.
    var outConnectionVector: Entity? {
        findEntity(named: SwiftSplashTrackPieces.outConnectionVectorName)
    }
    
    /// Finds the entity containing the connectable component in this entity or one of its ancestors.
    var connectableAncestor: Entity? {
        if connectableComponent != nil {
            return self
        }
        var nextParent: Entity? = parent
        
        while nextParent != nil {
            if nextParent?.connectableComponent != nil {
                return nextParent
            }
            nextParent = nextParent?.parent
        }
        return nil
    }
    
    /// Each track piece other than the start, goal, and placeholder pieces have a child transform
    /// that identifies where to place its edit UI. This returns it.
    var uiAnchor: Entity? {
        self.findEntity(named: uiPositionMarker)
    }
    
    var instructionsMarker: Entity? {
        self.findEntity(named: instructionsMarkerName)
    }
}

public extension Entity {
    
    /// Recursive search of children looking for any descendants with a specific component and calling a closure with them.
    func forEachDescendant<T: Component>(withComponent componentClass: T.Type, _ closure: (Entity, T) -> Void) {
        for child in children {
            if let component = child.components[componentClass] {
                closure(child, component)
            }
            child.forEachDescendant(withComponent: componentClass, closure)
        }
    }
}
