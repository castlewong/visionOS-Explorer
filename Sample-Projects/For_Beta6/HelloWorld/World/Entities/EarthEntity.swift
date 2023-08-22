/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An entity that represents the Earth and all its moving parts.
*/

import RealityKit
import SwiftUI
import WorldAssets

/// An entity that represents the Earth and all its moving parts.
class EarthEntity: Entity {

    // MARK: - Sub-entities

    /// The model that draws the Earth's surface features.
    private let earth: Entity

    /// An entity that rotates 23.5° to create axial tilt.
    private let equatorialPlane = Entity()

    /// An entity that provides a configurable rotation,
    /// separate from the day/night cycle.
    private let rotator = Entity()

    /// A physical representation of the Earth's north and south poles.
    private let pole: Entity

    /// The Earth's one natural satellite.
    private let moon: SatelliteEntity

    /// A container for artificial satellites.
    private let satellites = Entity()

    // MARK: - Internal state

    /// Keep track of solar intensity and only update when it changes.
    private var currentSunIntensity: Float? = nil

    // MARK: - Initializers

    /// Creates a new blank earth entity.
    @MainActor required init() {
        earth = Entity()
        pole = Entity()
        moon = SatelliteEntity()
        super.init()
    }

    /// Creates a new earth entity with the specified configuration.
    ///
    /// - Parameters:
    ///   - configuration: Information about how to configure the Earth.
    ///   - satelliteConfiguration: An array of configuration structures, one
    ///     for each artificial satellite. The initializer creates one
    ///     satellite model for each element of the array. Pass an empty
    ///     array to avoid creating any artificial satellites.
    ///   - moonConfiguration: A satellite configuration structure that's
    ///     specifically for the Moon. Set to `nil` to avoid creating a
    ///     Moon entity.
    init(
        configuration: Configuration,
        satelliteConfiguration: [SatelliteEntity.Configuration],
        moonConfiguration: SatelliteEntity.Configuration?
    ) async {
        do { // Load assets.
            earth = try await Entity(
                named: configuration.isCloudy ? "Earth" : "Globe",
                in: worldAssetsBundle
            )
            pole = try await Entity(named: "Pole", in: worldAssetsBundle)
            moon = await SatelliteEntity(.orbitMoonDefault)
            for configuration in satelliteConfiguration {
                await satellites.addChild(SatelliteEntity(configuration))
            }
        } catch {
            fatalError("Failed to load a model asset.")
        }

        super.init()

        // Attach to the Earth to a set of entities that enable axial
        // tilt and a configured amount of rotation around the axis.
        self.addChild(equatorialPlane)
        equatorialPlane.addChild(rotator)
        rotator.addChild(earth)

        // Attach the pole to the Earth to ensure that it
        // moves, tilts, rotates, and scales with the Earth.
        earth.addChild(pole)

        // The Moon's orbit isn't affected by the tilt of the Earth, so attach
        // the Moon to the root entity.
        self.addChild(moon)

        // The inclination of artificial satellite orbits is measured relative
        // to the Earth's equator, so attach the satellite container to the
        // equatorial plane entity.
        equatorialPlane.addChild(satellites)

        // Configure everything for the first time.
        update(
            configuration: configuration,
            satelliteConfiguration: satelliteConfiguration,
            moonConfiguration: moonConfiguration,
            animateUpdates: false)
    }

    // MARK: - Updates

    /// Updates all the entity's configurable elements.
    ///
    /// - Parameters:
    ///   - configuration: Information about how to configure the Earth.
    ///   - satelliteConfiguration: An array of configuration structures, one
    ///     for each artificial satellite.
    ///   - moonConfiguration: A satellite configuration structure that's
    ///     specifically for the Moon.
    ///   - animateUpdates: A Boolean that indicates whether changes to certain
    ///     configuration values should be animated.
    func update(
        configuration: Configuration,
        satelliteConfiguration: [SatelliteEntity.Configuration],
        moonConfiguration: SatelliteEntity.Configuration?,
        animateUpdates: Bool
    ) {
        // Indicate the position of the sun for use in turning the ground
        // lights on and off.
        earth.sunPositionComponent = SunPositionComponent(Float(configuration.sunAngle.radians))
        
        // Set a static rotation of the tilted Earth, driven from the configuration.
        rotator.orientation = configuration.rotation

        // Set the speed of the Earth's automatic rotation on it's axis.
        if var rotation: RotationComponent = earth.components[RotationComponent.self] {
            rotation.speed = configuration.speed
            earth.components[RotationComponent.self] = rotation
        } else {
            earth.components.set(RotationComponent(speed: configuration.speed))
        }

        // Update the Moon.
        moon.update(
            configuration: moonConfiguration ?? .disabledMoon,
            speed: configuration.speed,
            traceAnchor: self)

        // Update the artificial satellites.
        for satellite in satellites.children {
            guard let satelliteConfiguration = satelliteConfiguration.first(where: { $0.name == satellite.name }) else { continue }
            (satellite as? SatelliteEntity)?.update(
                configuration: satelliteConfiguration,
                speed: configuration.speed,
                traceAnchor: earth)
        }

        // Configure the poles.
        pole.isEnabled = configuration.showPoles
        pole.scale = [
            configuration.poleThickness,
            configuration.poleLength,
            configuration.poleThickness]

        // Set the sunlight, if corresponding controls have changed.
        let sunIntensity = configuration.showSun ? configuration.sunIntensity : nil
        if sunIntensity != currentSunIntensity {
            setSunlight(intensity: configuration.showSun ? configuration.sunIntensity : nil)
            currentSunIntensity = sunIntensity
        }

        // Tilt the axis according the current date. For the tilt to create
        // a particular date, the sun must be located along the positive x-axis.
        // However the magnitude of the tilt is accurate in any case.
        equatorialPlane.updateTransform(
            rotation: tilt(date: configuration.date),
            withAnimation: animateUpdates)

        self.updateTransform(
            scale: SIMD3(repeating: configuration.scale),
            translation: configuration.position,
            withAnimation: animateUpdates)
    }

    /// Calculates the orientation of the Earth's tilt on a specified date.
    ///
    /// This method assumes the sun appears at some distance from the Earth
    /// along the negative x-axis.
    ///
    /// - Parameter date: The date that the Earth's tilt represents.
    ///
    /// - Returns: A representation of tilt that you apply to an Earth model.
    private func tilt(date: Date?) -> simd_quatf {
        // Assume a constant magnitude for the Earth's tilt angle.
        let tiltAngle: Angle = .degrees(date == nil ? 0 : 23.5)

        // Find the day in the year corresponding to the date.
        let calendar = Calendar.autoupdatingCurrent
        let day = calendar.ordinality(of: .day, in: .year, for: date ?? Date()) ?? 1

        // Get an axis angle corresponding to the day of the year, assuming
        // the sun appears in the negative x direction.
        let axisAngle: Float = (Float(day) / 365.0) * 2.0 * .pi

        // Create an axis that points the northern hemisphere toward the
        // sun along the positive x-axis when axisAngle is zero.
        let tiltAxis: SIMD3<Float> = [
            sin(axisAngle),
            0,
            -cos(axisAngle)
        ]

        // Create and return a tilt orientation from the angle and axis.
        return simd_quatf(angle: Float(tiltAngle.radians), axis: tiltAxis)
    }
}

