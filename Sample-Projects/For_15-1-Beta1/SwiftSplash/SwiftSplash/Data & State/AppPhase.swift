/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A simple state machine used to keep track of the app's current state.
*/
import Foundation

/// Enum that tracks the current phase of the game by implementing a simple state machine.
public enum AppPhase: String, Codable, Sendable, Equatable {
    case startingUp         // Launching app
    case loadingAssets      // Loading assets from the Reality Composer Pro project
    case waitingToStart     // At the main menu
    case placingStartPiece  // Placing the first piece of track
    case draggingStartPiece // Has started, but not finished, dragging the start piece
    case buildingTrack      // Working on the ride
    case rideRunning        // Ride animations running
    
    /// Controls whether the mixed reality view containing the ride is visible.
    var isImmersed: Bool {
        switch self {
            case .startingUp, .loadingAssets, .waitingToStart:
                return false
            case .placingStartPiece, .draggingStartPiece, .buildingTrack, .rideRunning:
                return true
        }
    }
    
    /// Returns `True` if it's possible to transition to the specified phase from the currrent one.
    func canProgress(to phase: AppPhase) -> Bool {
        switch self {
            case .startingUp:
                return phase == .loadingAssets
            case .loadingAssets:
                return phase == .waitingToStart
            case .waitingToStart:
                return phase == .placingStartPiece
            case .placingStartPiece:
                return phase == .draggingStartPiece
            case .draggingStartPiece:
                return [.waitingToStart, .buildingTrack].contains(phase)
            case .buildingTrack:
                return [.rideRunning, .waitingToStart].contains(phase)
            case .rideRunning:
                return [.waitingToStart, .buildingTrack].contains(phase)
        }
    }
    
    /// Requests a phase transition.
    @discardableResult
    mutating public func transition(to newPhase: AppPhase) -> Bool {
        logger.info("Phase change to \(newPhase.rawValue)")
        guard self != newPhase else {
            logger.debug("Attempting to change phase to \(newPhase.rawValue) but already in that state. Treating as a no-op.")
            return false
        }
        guard canProgress(to: newPhase) else {
            logger.error("Requested transition to \(newPhase.rawValue), but that's not a valid transition.")
            return false
        }
        self = newPhase
        return true
    }
  
}
