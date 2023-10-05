/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Configuration values and global variables.
*/

import Foundation
import OSLog
import RealityKit

/// Indicate how close two compatible connection points have to be
/// in order for power to be transferred.
let maximumConnectionDistance = Float(0.01)

/// Indicate how close two compatible connection points have to be
/// in order to snap.
let maximumSnapDistance = Float(0.1)

/// The app doesn't continue snapping pieces forever. Constantly snapping pieces could
/// result in weird interactions when connection points are close.
var secondsAfterDragToContinueSnap = TimeInterval(0.025)

/// The piece being dragged or rotated using gesture entities.
var draggedPiece: Entity? = nil

/// The speed of the ride animations as a multiplier of the original animation in the USDZ file.
let animationSpeedMultiplier = Double(1.0)

/// Indicate how close two connection points must be to be considered connected.
let snapEpsilon = 0.000_000_1

/// Set this to true to tell the ride animation code that it should stop.
var shouldCancelRide = false

/// Set this to true to pause the current ride animation.
var shouldPauseRide = false

/// If `shouldPauseRide` is `true`, this identifies when the pause started.
var pauseStartTime: TimeInterval = 0

/// Use to keep a reference to ride animations.
var rideAnimationcontrollers = [AnimationPlaybackController]()

/// Indicate how long it takes to snap rotation to the nearest 90°. The maximum snap rotation
/// is 45°, so this value represents how long it takes to snap rotate 45°.
var rotateSnapTime: TimeInterval = 10

/// Water should not flow until the doors open. The app uses this to determine
/// when to start the water flowing after the start piece animations start
var waterStartDelay: TimeInterval = 9.6

/// The fish starts making ambient sounds after the ride runs for this long.
var ambientSoundsDelay: TimeInterval = 17.0

var rotatingParentNodeName = "Rotating Parent"

/// When someone is dragging one or more track pieces using a gesture, this is `true`.
var isDragging = false

/// When someone is rotating one or more track pieces using a gesture, this is `true`.
var isRotating = false

var isSnapping = false
