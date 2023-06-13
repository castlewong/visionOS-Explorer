/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents the app's user interface.
*/

import SwiftUI

// The app uses `LibraryView` as its main UI.
struct ContentView: View {
    
    /// The library's selection path.
    @State private var navigationPath = [Video]()
    /// A Boolean value that indicates whether the app is currently presenting an immersive space.
    @State private var isPresentingSpace = false
    /// The app's player model.
    @Environment(PlayerModel.self) private var player
    
    var body: some View {
        #if os(xrOS)
        switch player.presentation {
        case .fullScreen:
            // Present the player full screen and begin playback.
            PlayerView()
                .onAppear {
                    player.play()
                }
        default:
            // Show the app's content library by default.
            LibraryView(path: $navigationPath, isPresentingSpace: $isPresentingSpace)
        }
        #else
        LibraryView(path: $navigationPath)
            // A custom modifier that shows the player in a fullscreen modal presentation.
            .fullScreenCoverPlayer(player: player)
        #endif
    }
}

#Preview {
    ContentView()
        .environment(PlayerModel())
}
