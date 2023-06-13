/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents the video player.
*/

import SwiftUI

/// Constants that define the style of controls a player presents.
enum PlayerControlsStyle {
    /// A value that indicates to use the system interface that AVPlayerViewController provides.
    case system
    /// A value that indicates to use compact controls that display a play/pause button.
    case custom
}

/// A view that presents the video player.
struct PlayerView: View {
    
    let controlsStyle: PlayerControlsStyle
    @State private var showContextualActions = false
    @Environment(PlayerModel.self) private var model
    
    /// Creates a new player view.
    init(controlsStyle: PlayerControlsStyle = .system) {
        self.controlsStyle = controlsStyle
    }
    
    var body: some View {
        switch controlsStyle {
        case .system:
            SystemPlayerView(showContextualActions: showContextualActions)
                .onChange(of: model.shouldProposeNextVideo) { oldValue, newValue in
                    if oldValue != newValue {
                        showContextualActions = newValue
                    }
                }
        case .custom:
            InlinePlayerView()
        }
    }
}
