/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A toggle that activates or deactivates the solar system scene.
*/

import SwiftUI

/// A toggle that activates or deactivates the solar system scene.
struct SolarSystemToggle: View {
    @Environment(ViewModel.self) private var model
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some View {
        Button {
            Task {
                if model.isShowingSolar {
                    await dismissImmersiveSpace()
                } else {
                    await openImmersiveSpace(id: Module.solar.name)
                }
            }
        } label: {
            if model.isShowingSolar {
                Label(
                    "Exit the Solar System",
                    systemImage: "arrow.down.right.and.arrow.up.left")
            } else {
                Text(Module.solar.callToAction)
            }
        }
    }
}

#Preview {
    SolarSystemToggle()
        .environment(ViewModel())
}
