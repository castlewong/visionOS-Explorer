/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A detail view that presents information about different module types.
*/

import SwiftUI

/// A detail view that presents information about different module types.
struct ModuleDetail: View {
    @Environment(ViewModel.self) private var model

    var module: Module

    var body: some View {
        @Bindable var model = model

        GeometryReader { proxy in
            let textWidth = min(max(proxy.size.width * 0.4, 300), 500)
            let imageWidth = min(max(proxy.size.width - textWidth, 300), 700)
            ZStack {
                HStack(spacing: 60) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(module.heading)
                            .font(.system(size: 50, weight: .bold))
                            .padding(.bottom, 15)

                        Text(module.overview)
                            .padding(.bottom, 30)

                        switch module {
                        case .globe:
                            WindowToggle(
                                title: module.callToAction,
                                id: module.name,
                                isShowing: $model.isShowingGlobe)
                        case .orbit:
                            SpaceToggle(
                                title: module.callToAction,
                                id: module.name,
                                isShowing: $model.isShowingOrbit)
                        case .solar:
                            SpaceToggle(
                                title: module.callToAction,
                                id: module.name,
                                isShowing: $model.isShowingSolar)
                        }
                    }
                    .frame(width: textWidth, alignment: .leading)

                    module.detailView
                        .frame(width: imageWidth, alignment: .center)
                }
                .offset(y: -30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(70)
        .background {
            if module == .solar {
                Image("SolarBackground")
                    .resizable()
                    .scaledToFill()
            }
        }

        // A settings button in an ornament,
        // visible only when `showDebugSettings` is true.
        .settingsButton(module: module)
   }
}

extension Module {
    @ViewBuilder
    fileprivate var detailView: some View {
        switch self {
        case .globe: GlobeModule()
        case .orbit: OrbitModule()
        case .solar: SolarSystemModule()
        }
    }
}

/// A toggle that activates or deactivates a window with
/// the specified identifier.
private struct WindowToggle: View {
    var title: String
    var id: String
    @Binding var isShowing: Bool

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        Toggle(title, isOn: $isShowing)
            .onChange(of: isShowing) { wasShowing, isShowing in
                if isShowing {
                    openWindow(id: id)
                } else {
                    dismissWindow(id: id)
                }
            }
            .toggleStyle(.button)
    }
}

/// A toggle that activates or deactivates the immersive space with
/// the specified identifier.
private struct SpaceToggle: View {
    var title: String
    var id: String
    @Binding var isShowing: Bool

    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some View {
        Toggle(title, isOn: $isShowing)
            .onChange(of: isShowing) { wasShowing, isShowing in
                Task {
                    if isShowing {
                        await openImmersiveSpace(id: id)
                    } else {
                        await dismissImmersiveSpace()
                    }
                }
            }
            .toggleStyle(.button)
    }
}

#Preview("Globe") {
    NavigationStack {
        ModuleDetail(module: .globe)
            .environment(ViewModel())
    }
}

#Preview("Orbit") {
    NavigationStack {
        ModuleDetail(module: .orbit)
            .environment(ViewModel())
    }
}

#Preview("Solar System") {
    NavigationStack {
        ModuleDetail(module: .solar)
            .environment(ViewModel())
    }
}
