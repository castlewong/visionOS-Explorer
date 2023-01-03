/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The module detail content that's specific to the solar system module.
*/

import SwiftUI

/// The module detail content that's specific to the solar system module.
struct SolarSystemModule: View {
    var body: some View {
        Image("SolarHero")
            .resizable()
            .scaledToFit()
    }
}

#Preview {
    SolarSystemModule()
        .padding()
}
