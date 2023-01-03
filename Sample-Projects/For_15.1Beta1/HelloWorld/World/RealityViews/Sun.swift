/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model of the sun.
*/

import SwiftUI
import RealityKit
import WorldAssets

/// A model of the sun.
struct Sun: View {
    var scale: Float = 1
    var position: SIMD3<Float> = .zero

    /// The sun entity that the view creates and stores for later updates.
    @State private var sun: Entity?

    var body: some View {
        RealityView { content in
            guard let sun = await WorldAssets.entity(named: "Sun") else {
                return
            }

            content.add(sun)
            self.sun = sun
            configure()

        } update: { content in
            configure()
        }
    }

    /// Configures the model based on the current set of inputs.
    private func configure() {
        sun?.scale = SIMD3(repeating: scale)
        sun?.position = position
    }
}

#Preview {
    Sun(scale: 0.1)
}
