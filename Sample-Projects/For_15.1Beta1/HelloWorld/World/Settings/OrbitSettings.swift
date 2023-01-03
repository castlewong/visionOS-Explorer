/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Debug setting controls for the orbit module.
*/

import SwiftUI

/// Debug setting controls for the orbit module.
struct OrbitSettings: View {
    @Environment(ViewModel.self) private var model

    var body: some View {
        @Bindable var model = model

        VStack {
            Text("Orbit module debug settings")
                .font(.title)
            Form {
                EarthSettings(configuration: $model.orbitEarth)
                SatelliteSettings(configuration: $model.orbitSatellite)
                SatelliteSettings(configuration: $model.orbitMoon)
                Section("System") {
                    Grid(alignment: .leading, verticalSpacing: 20) {
                        Button("Reset") {
                            model.orbitEarth = .orbitEarthDefault
                            model.orbitSatellite = .orbitSatelliteDefault
                            model.orbitMoon = .orbitMoonDefault
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    OrbitSettings()
        .frame(width: 500)
        .environment(ViewModel())
}
