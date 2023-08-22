/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Configuration information for Earth entities.
*/

import SwiftUI

extension EarthEntity {
    /// Configuration information for Earth entities.
    struct Configuration {
        var isCloudy: Bool = false

        var scale: Float = 0.6
        var rotation: simd_quatf = .init(angle: 0, axis: [0, 1, 0])
        var speed: Float = 0
        var position: SIMD3<Float> = .zero
        var date: Date? = nil

        var showPoles: Bool = false
        var poleLength: Float = 0.925
        var poleThickness: Float = 0.75

        var showSun: Bool = true
        var sunIntensity: Float = 14
        var sunAngle: Angle = .degrees(280)

        static var globeEarthDefault: Configuration = .init()

        static var orbitEarthDefault: Configuration = .init(
            scale: 0.4,
            speed: 0.1,
            date: Date())

        static var solarEarthDefault: Configuration = .init(
            isCloudy: true,
            scale: 4.6,
            speed: 0.045,
            position: [-2, 0.4, -5],
            date: Date())
    }
}
