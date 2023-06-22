/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Custom view modifiers that the app defines.
*/

import SwiftUI

extension View {
    #if os(xrOS)
    func updateImmersionOnChange(of path: Binding<[Video]>, isPresentingSpace: Binding<Bool>) -> some View {
        self.modifier(ImmersiveSpacePresentationModifier(navigationPath: path, isPresentingSpace: isPresentingSpace))
    }
    #endif
    
    func fullScreenCoverPlayer(player: PlayerModel) -> some View {
        self.modifier(FullScreenCoverModifier(player: player))
    }
}

#if os(xrOS)
private struct ImmersiveSpacePresentationModifier: ViewModifier {
    
    @Environment(\.openImmersiveSpace) private var openSpace
    @Environment(\.dismissImmersiveSpace) private var dismissSpace
    /// The current phase for the scene, which can be active, inactive, or background.
    @Environment(\.scenePhase) private var scenePhase
    
    @Binding var navigationPath: [Video]
    @Binding var isPresentingSpace: Bool
    
    func body(content: Content) -> some View {
        content
            .onChange(of: navigationPath) {
                Task {
                    // The selection path becomes empty when the user returns to the main library window.
                    if navigationPath.isEmpty {
                        if isPresentingSpace {
                            // Dismiss the space and return the user to their real-world space.
                            await dismissSpace()
                            isPresentingSpace = false
                        }
                    } else {
                        guard !isPresentingSpace else { return }
                        // The navigationPath has one video, or is empty.
                        guard let video = navigationPath.first else { fatalError() }
                        // Await the request to open the destionation and set the state accordingly.
                        switch await openSpace(value: video.destination) {
                        case .opened: isPresentingSpace = true
                        default: isPresentingSpace = false
                        }
                    }
                }
            }
            // Close the space and unload media when the user backgrounds the app.
            .onChange(of: scenePhase) { _, newPhase in
                if isPresentingSpace, newPhase == .background {
                    Task {
                        await dismissSpace()
                    }
                }
            }
    }
}
#endif

private struct FullScreenCoverModifier: ViewModifier {
    
    let player: PlayerModel
    @State private var isPresentingPlayer = false
    
    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresentingPlayer) {
                PlayerView()
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.reset()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
            // Observe the player's presentation property.
            .onChange(of: player.presentation, { _, newPresentation in
                isPresentingPlayer = newPresentation == .fullScreen
            })
    }
}

