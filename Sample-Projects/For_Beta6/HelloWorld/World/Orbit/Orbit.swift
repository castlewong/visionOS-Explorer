/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model content for the orbit module.
*/

import SwiftUI
import RealityKit

/// The model content for the orbit module.
struct Orbit: View {
    @Environment(ViewModel.self) private var model

    var body: some View {
        Earth(
            earthConfiguration: model.orbitEarth,
            satelliteConfiguration: [model.orbitSatellite],
            moonConfiguration: model.orbitMoon
        )
        .placementGestures(initialPosition: Point3D([475, -1200.0, -1200.0]))
    }
}
