/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Convenience methods for drawing a trace behind a satellite.
*/

import SwiftUI
import RealityKit

extension Entity {
    /// Resets all the elements of a trace.
    func resetTrace(recursive: Bool = false) {
        if var trace: TraceComponent = components[TraceComponent.self] {
            trace.mesh.positions.removeAll()
            trace.model?.removeFromParent()
            trace.model = nil
            self.components[TraceComponent.self] = trace
        }
        if recursive {
            for child in children {
                child.resetTrace(recursive: recursive)
            }
        }
    }

    /// Updates the configuration of a trace.
    func updateTrace(
        anchor: Entity,
        width: Float,
        isVisible: Bool,
        isPaused: Bool
    ) {
        if isVisible {
            if !components.has(TraceComponent.self) {
                components.set(TraceComponent(anchor: anchor, width: width))
            } else if var trace: TraceComponent = components[TraceComponent.self] {
                trace.isPaused = isPaused
                trace.mesh.width = width
                components[TraceComponent.self] = trace
            }
        } else {
            if let trace: TraceComponent = components[TraceComponent.self] {
                trace.model?.removeFromParent()
            }
            components[TraceComponent.self] = nil
        }
    }
}
