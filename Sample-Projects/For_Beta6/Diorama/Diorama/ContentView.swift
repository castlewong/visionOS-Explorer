/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main SwiftUI view.
*/

import SwiftUI
import RealityKit

struct ContentView: View {
    let spaceId: String
    var viewModel: ViewModel

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    var areControlsShowing: Bool {
        viewModel.rootEntity != nil && viewModel.showImmersiveContent
    }
    
    var body: some View {
        @Bindable var viewModel = viewModel

        VStack {
            Spacer()
            Grid(alignment: .leading, verticalSpacing: 30) {
                Toggle(isOn: $viewModel.showImmersiveContent) {
                    Text("Show Diorama")
                }
                .onChange(of: viewModel.showImmersiveContent) {
                    Task {
                        if viewModel.showImmersiveContent {
                            viewModel.resetAudio()
                            await openImmersiveSpace(id: spaceId)
                        } else {
                            await dismissImmersiveSpace()
                        }
                    }
                }
                
                GridRow {
                    Text("Morph")
                    Slider(value: $viewModel.sliderValue, in: (0.0)...(1.0))
                        .onChange(of: viewModel.sliderValue) { _, _ in
                            update()
                        }
                        .onAppear {
                            if let value = viewModel.terrainMaterialValue {
                                viewModel.sliderValue = value
                            }
                            update()
                        }
                }
                .disabled(!areControlsShowing)
                .opacity(areControlsShowing ? 1 : 0.5)

                GridRow {
                    Text("Scale")
                    Slider(value: $viewModel.contentScaleSliderValue)
                        .onChange(of: viewModel.contentScaleSliderValue) { _, _ in
                            viewModel.updateScale()
                        }
                }
                .disabled(!areControlsShowing)
                .opacity(areControlsShowing ? 1 : 0.5)
            }
            .animation(.default, value: areControlsShowing)
            .frame(width: 500)
            .padding(30)
            .glassBackgroundEffect()
        }
    }

    private func update() {
        viewModel.updateTerrainMaterial()
        viewModel.updateRegionSpecificOpacity()
    }
}

#Preview("Hidden") {
    ContentView(
        spaceId: "Immersive",
        viewModel: ViewModel(rootEntity: Entity(), showImmersiveContent: false)
    )
}

#Preview("Showing") {
    ContentView(
        spaceId: "Immersive",
        viewModel: ViewModel(rootEntity: Entity(), showImmersiveContent: true)
    )
}
