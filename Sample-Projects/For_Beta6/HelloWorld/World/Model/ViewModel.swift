/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The stored data for the app.
*/

import SwiftUI

/// The data that the app uses to configure its views.
@Observable
class ViewModel {
    
    // MARK: - Navigation
    var navigationPath: [Module] = []
    var titleText: String = ""
    var isTitleFinished: Bool = false
    var finalTitle: String = "Hello World"

    // MARK: - Globe
    var isShowingGlobe: Bool = false
    var globeEarth: EarthEntity.Configuration = .globeEarthDefault
    var isGlobeRotating: Bool = false
    var globeTilt: GlobeTilt = .none

    // MARK: - Orbit
    var isShowingOrbit: Bool = false
    var orbitEarth: EarthEntity.Configuration = .orbitEarthDefault
    var orbitSatellite: SatelliteEntity.Configuration = .orbitSatelliteDefault
    var orbitMoon: SatelliteEntity.Configuration = .orbitMoonDefault

    // MARK: - Solar System
    var isShowingSolar: Bool = false
    var solarEarth: EarthEntity.Configuration = .solarEarthDefault
    var solarSatellite: SatelliteEntity.Configuration = .solarTelescopeDefault
    var solarMoon: SatelliteEntity.Configuration = .solarMoonDefault

    var solarSunDistance: Double = 700
    var solarSunPosition: SIMD3<Float> {
        [Float(solarSunDistance * sin(solarEarth.sunAngle.radians)),
         0,
         Float(solarSunDistance * cos(solarEarth.sunAngle.radians))]
    }
}
