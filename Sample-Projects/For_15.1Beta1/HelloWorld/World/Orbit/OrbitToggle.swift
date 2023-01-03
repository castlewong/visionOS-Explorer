/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A toggle that activates or deactivates the orbit scene.
*/

import SwiftUI

/// A toggle that activates or deactivates the orbit scene.
struct OrbitToggle: View {
    @Environment(ViewModel.self) private var model
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some View {
        @Bindable var model = model

        Toggle(Module.orbit.callToAction, isOn: $model.isShowingOrbit)
            .onChange(of: model.isShowingOrbit) { _, isShowing in
                Task {
                    if isShowing {
                        await openImmersiveSpace(id: Module.orbit.name)
                    } else {
                        await dismissImmersiveSpace()
                    }
                }
            }
            .toggleStyle(.button)
    }
}

#Preview {
    OrbitToggle()
        .environment(ViewModel())
}
