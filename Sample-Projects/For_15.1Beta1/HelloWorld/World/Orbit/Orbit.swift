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

    @State var axZoomIn: Bool = false
    @State var axZoomOut: Bool = false

    var body: some View {
        Earth(
            earthConfiguration: model.orbitEarth,
            satelliteConfiguration: [model.orbitSatellite],
            moonConfiguration: model.orbitMoon
        ) { event in
            if event.key.defaultValue == EarthEntity.AccessibilityActions.zoomIn.name.defaultValue {
                axZoomIn.toggle()
            } else if event.key.defaultValue == EarthEntity.AccessibilityActions.zoomOut.name.defaultValue {
                axZoomOut.toggle()
            }
        }
        .placementGestures(
            initialPosition: Point3D([475, -1200.0, -1200.0]),
            axZoomIn: axZoomIn,
            axZoomOut: axZoomOut)
        .onDisappear {
            model.isShowingOrbit = false
        }
    }
}
