/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Settings for the satellite entities.
*/

import SwiftUI

/// Controls for settings that relate to a satellite entity.
struct SatelliteSettings: View {
    @Binding var configuration: SatelliteEntity.Configuration

    var body: some View {
        Section(configuration.name) {
            Grid(alignment: .leading, verticalSpacing: 20) {
                Toggle("Visible", isOn: $configuration.isVisible)
                SliderGridRow(
                    title: "Speed ratio",
                    value: $configuration.speedRatio,
                    range: 0 ... 50,
                    fractionLength: 1)
                SliderGridRow(
                    title: "Altitude",
                    value: $configuration.altitude,
                    range: 0 ... 10,
                    fractionLength: 2)
                SliderGridRow(
                    title: "Inclination",
                    value: inclinationBinding,
                    range: 0 ... 90,
                    fractionLength: 0)
                SliderGridRow(
                    title: "Scale",
                    value: $configuration.scale,
                    range: 0 ... 5,
                    fractionLength: 2)

                Divider()

                Toggle("Trace", isOn: $configuration.isTraceVisible)
                SliderGridRow(
                    title: "Trace width",
                    value: $configuration.traceWidth,
                    range: 0 ... 1000)
            }
        }
    }

    var inclinationBinding: Binding<Float> {
        Binding<Float>(
            get: { Float(configuration.inclination.degrees) },
            set: { configuration.inclination = .degrees(Double($0)) }
        )
    }
}

