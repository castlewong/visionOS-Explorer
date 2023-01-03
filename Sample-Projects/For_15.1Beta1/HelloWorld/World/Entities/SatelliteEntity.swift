/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A satellite entity.
*/

import RealityKit
import SwiftUI
import WorldAssets

/// A satellite entity.
class SatelliteEntity: Entity {
    
    // MARK: - Sub-entities

    private var satellite = Entity()
    private let box = Entity()
    private let orbit = Entity()

    // MARK: - Initializers

    @MainActor required init() {
        super.init()
    }

    init(_ configuration: Configuration) async {
        super.init()

        // Load the satellite model.
        guard let satellite = await WorldAssets.entity(named: configuration.name) else {
            return
        }
        self.satellite = satellite

        // An entity whose orientation controls the inclination of the orbit.
        name = configuration.name
        isEnabled = configuration.isVisible

        // The entity that creates the satellite's orbit using a rotation component.
        orbit.components.set(RotationComponent(speed: 0))
        orbit.orientation = .init(angle: Float(configuration.initialRotation.radians), axis: [0, 1, 0])
        self.addChild(orbit)

        // A container for the satellite that can be scaled and
        // positioned without interfering with the trace.
        orbit.addChild(box)

        // The satellite model that draws an optional trace.
        box.addChild(satellite)
    }
    
    func update(
        configuration: Configuration,
        speed: Float,
        traceAnchor: Entity
    ) {
        var resetTrace = !configuration.isTraceVisible

        let newOrientation = simd_quatf(angle: Float(configuration.inclination.radians), axis: [0, 0, 1])
        if newOrientation != self.orientation {
            resetTrace = true
        }
        orientation = newOrientation
        isEnabled = configuration.isVisible

        if var rotation: RotationComponent = orbit.components[RotationComponent.self] {
            rotation.speed = configuration.speedRatio * speed
            orbit.components[RotationComponent.self] = rotation
        }

        box.scale = SIMD3(repeating: configuration.scale)
        box.position = [0, 0, configuration.altitude]

        satellite.updateTrace(
            anchor: traceAnchor,
            width: configuration.traceWidth,
            isVisible: configuration.isTraceVisible,
            isPaused: (configuration.speedRatio * speed) == 0)
        if resetTrace {
            satellite.resetTrace()
        }
    }
}

