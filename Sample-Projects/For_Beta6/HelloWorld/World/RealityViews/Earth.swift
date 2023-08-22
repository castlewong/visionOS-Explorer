/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model of the Earth.
*/

import SwiftUI
import RealityKit
import WorldAssets

/// The model of the Earth.
struct Earth: View {
    var earthConfiguration: EarthEntity.Configuration = .init()
    var satelliteConfiguration: [SatelliteEntity.Configuration] = []
    var moonConfiguration: SatelliteEntity.Configuration? = nil
    var animateUpdates: Bool = false

    /// The Earth entity that the view creates and stores for later updates.
    @State private var earthEntity: EarthEntity?

    var body: some View {
        RealityView { content in
            // Create an earth entity with tilt, rotation, a moon, and so on.
            let earthEntity = await EarthEntity(
                configuration: earthConfiguration,
                satelliteConfiguration: satelliteConfiguration,
                moonConfiguration: moonConfiguration
            )
            content.add(earthEntity)

            // Store for later updates.
            self.earthEntity = earthEntity

        } update: { content in
            // Reconfigure everything when any configuration changes.
            earthEntity?.update(
                configuration: earthConfiguration,
                satelliteConfiguration: satelliteConfiguration,
                moonConfiguration: moonConfiguration,
                animateUpdates: animateUpdates)
        }
    }
}

#Preview {
    Earth(
        earthConfiguration: EarthEntity.Configuration.orbitEarthDefault,
        satelliteConfiguration: [
            SatelliteEntity.Configuration(
                name: "Satellite",
                isVisible: true,
                inclination: .degrees(30),
                speedRatio: 10,
                scale: 1,
                altitude: 0.4,
                traceWidth: 400,
                isTraceVisible: true)
        ]
    )
}
