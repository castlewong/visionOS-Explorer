/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Components the app uses to mark entities in the Reality Composer Pro project.
*/

import Foundation
import RealityKit

/// The component, usually added in Reality Composer Pro, that identifies an `Entity` as
/// marking the location where the "Place Start View" attachment goes.
public struct PlaceStartPieceUIMarkerComponent: Component, Codable {
}

/// The component, usually added in Reality Composer Pro, that identifies an `Entity` as
/// marking the location where the "Place Start View" attachment goes.
public struct EditUILocationMarkerComponent: Component, Codable {
}

/// The component, usually added in Reality Composer Pro, that identifies an `Entity` as having
/// an animation that plays while the ride is running.
public struct RideAnimationComponent: Component, Codable {
    /// A Boolean that identifies whether this entity will be visible when the ride isn't running. If set
    /// to `true`, the entity will always be visible, but will only animated during the ride run when it's
    /// scene is the active one. If set to `false`, the entity is hidden when not animating.
    public var isPersistent = true
    
    /// How far into the ride animation to trigger the next animation.
    public var duration = 1.0
    
    /// If set to `true`, the animations run during the entire ride, not just when that one track piece is active.
    /// `isPersistent` must also be `true` for this to work because otherwise, the entity will be hidden
    /// when its track piece isn't active.
    public var alwaysAnimates = false
    
    public var timecodeWhenNotPlaying: Double = 0
}

/// The component, usually added in Reality Composer Pro, that identifies an `Entity` as having
/// an idle animation that plays while the ride isn't running.
public struct IdleAnimationComponent: Component, Codable {
    /// Normally, idle animations play whenever the ride isn't running. If an animation needs
    /// to run after the ride ends rather than before (for example, the idle animation in the end piece)
    /// set this to `true`.
    public var playAtEndInsteadOfBeginning = false
}

/// The component, usually added in Reality Composer Pro, that identifies an `Entity` as being
/// ride water that only displays when the ride is running.
public struct RideWaterComponent: Component, Codable {
    /// Identifies at what point in vertical UV space fills the water completely..
    public var fillLevel: Float = 1.0
    
    /// Identifies how long it should take for this water to fill up.
    public var duration: Float = 1.0
}

/// The component, usually added in Reality Composer Pro, that identifies an `Entity` used
/// for the selection glow. These are hidden when the object isn't selected, and shown when they are.
public struct GlowComponent: Component, Codable {
    public var isTopPiece = false
}
