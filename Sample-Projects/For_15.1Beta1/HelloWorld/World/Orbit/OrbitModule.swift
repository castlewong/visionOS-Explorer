/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The module detail content that's specific to the orbit module.
*/

import SwiftUI
import RealityKit
import WorldAssets

private let modelDepth: Double = 200

/// The list of 3D models to display in the winow.
private enum Item: String, CaseIterable, Identifiable {
    case satellite, moon, telescope
    var id: Self { self }
    var name: String { rawValue.capitalized }
}

/// The module detail content that's specific to the orbit module.
struct OrbitModule: View {
    @Environment(ViewModel.self) private var model
    @State private var selection: Item = .satellite

    var body: some View {
        VStack(spacing: 100) {
            Color.clear
                .overlay {
                    ItemView(item: .satellite, orientation: [0.15, 0, 0.15])
                        .opacity(selection == .satellite ? 1 : 0)
                }
                .overlay {
                    ItemView(item: .moon)
                        .opacity(selection == .moon ? 1 : 0)
                }
                .overlay {
                    ItemView(item: .telescope, orientation: [-0.3, 0, 0])
                        .opacity(selection == .telescope ? 1 : 0)
                }
                .dragRotation(yawLimit: .degrees(20), pitchLimit: .degrees(20))
                .offset(z: modelDepth)

            Picker("Satellite", selection: $selection) {
                ForEach(Item.allCases) { item in
                    Text(item.name)
                }
            }
            .pickerStyle(.segmented)
            .accessibilitySortPriority(0)
            .frame(width: 350)
        }
    }
}

/// A 3D model loaded from the app's asset bundle.
private struct ItemView: View {
    var item: Item
    var orientation: SIMD3<Double> = .zero

    var body: some View {
        Model3D(named: item.name, bundle: worldAssetsBundle) { model in
            model.resizable()
                .scaledToFit()
                .rotation3DEffect(
                    Rotation3D(
                        eulerAngles: .init(angles: orientation, order: .xyz)
                    )
                )
                .frame(depth: modelDepth)
                .offset(z: -modelDepth / 2)
                .accessibilitySortPriority(1)
        } placeholder: {
            ProgressView()
                .offset(z: -modelDepth * 0.75)
        }
    }
}

#Preview {
    OrbitModule()
        .padding()
        .environment(ViewModel())
}
