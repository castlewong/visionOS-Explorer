/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Debug setting controls for the solar system module.
*/

import SwiftUI

/// Debug setting controls for the solar system module.
struct SolarSystemSettings: View {
    @Environment(ViewModel.self) private var model

    var body: some View {
        @Bindable var model = model
        
        VStack {
            Text("Solar system module debug settings")
                .font(.title)
            Form {
                EarthSettings(configuration: $model.solarEarth)
                SatelliteSettings(configuration: $model.solarSatellite)
                SatelliteSettings(configuration: $model.solarMoon)
                Section("Sun") {
                    Grid(alignment: .leading, verticalSpacing: 20) {
                        SliderGridRow(
                            title: "Distance to Earth",
                            value: $model.solarSunDistance,
                            range: 0 ... 1e3)
                    }
                }
                Section("System") {
                    Grid(alignment: .leading, verticalSpacing: 20) {
                        Button("Reset") {
                            model.solarEarth = .solarEarthDefault
                            model.solarSatellite = .solarTelescopeDefault
                            model.solarMoon = .solarMoonDefault
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SolarSystemSettings()
        .frame(width: 500)
        .environment(ViewModel())
}
