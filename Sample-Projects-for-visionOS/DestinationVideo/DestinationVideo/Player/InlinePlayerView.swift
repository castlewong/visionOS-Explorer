/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that display a simple inline video player with custom controls.
*/

import AVKit
import SwiftUI

struct InlinePlayerView: View {
    
    @Environment(PlayerModel.self) private var model
    
    var body: some View {
        ZStack {
            // A view that uses AVPlayerViewController to display the video content without controls.
            VideoContentView()
            // Custom inline controls to overlay on top of the video content.
            InlineControlsView()
        }
        .onDisappear {
            // If this view disappears, and it's not due to switching to fullscreen
            // presentation, clear the model's loaded media.
            if model.presentation != .fullScreen {
                model.reset()
            }
        }
    }
}

/// A view that defines a simple play/pause/replay button for the trailer player.
struct InlineControlsView: View {
    
    @Environment(PlayerModel.self) private var player
    @State private var isShowingControls = false
    
    var body: some View {
        VStack {
            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                .padding(8)
                .background(.thinMaterial)
                .clipShape(.circle)
                    
        }
        .font(.largeTitle)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            player.togglePlayback()
            isShowingControls = true
            // Execute the code below on the next runloop cycle.
            Task { @MainActor in
                if player.isPlaying {
                    dismissAfterDelay()
                }
            }
        }
    }
    
    func dismissAfterDelay() {
        Task {
            try! await Task.sleep(for: .seconds(3.0))
            withAnimation(.easeOut(duration: 0.3)) {
                isShowingControls = false
            }
        }
    }
}

/// A view that presents the video content of an player object.
///
/// This class is a view controller representable type that adapts the interface
/// of AVPlayerViewController. It disables the view controller's default controls
/// so it can draw custom controls over the video content.
private struct VideoContentView: UIViewControllerRepresentable {
    
    @Environment(PlayerModel.self) private var model
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = model.makePlayerViewController()
        // Disable the default system playback controls.
        controller.showsPlaybackControls = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

#Preview {
    InlineControlsView()
        .environment(PlayerModel())
}
