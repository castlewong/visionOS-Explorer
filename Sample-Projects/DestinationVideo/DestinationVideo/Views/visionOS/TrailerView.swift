/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays a poster image that you tap to watch a trailer.
*/

import SwiftUI

struct TrailerView: View {
    
    let video: Video
    
    @State private var isPosterVisible = true
    @Environment(PlayerModel.self) private var model
    
    var body: some View {
        if isPosterVisible {
            Button {
                // Loads the video for inline playback.
                model.loadVideo(video)
                withAnimation {
                    isPosterVisible = false
                }
            } label: {
                TrailerPosterView(video: video)
            }
            .buttonStyle(.plain)
        } else {
            PlayerView(controlsStyle: .custom)
                .onAppear {
                    if model.shouldAutoPlay {
                        model.play()
                    }
                }
        }
    }
}

/// A view that displays the poster image with a play button image over it.
private struct TrailerPosterView: View {
    
    let video: Video
    
    var body: some View {
        ZStack {
            Image(video.landscapeImageName)
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(spacing: 2) {
                Image(systemName: "play.fill")
                    .font(.system(size: 24.0))
                    .padding(12)
                    .background(.thinMaterial)
                    .clipShape(.circle)
                Text("Preview")
                    .font(.title3)
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 1, y: 1)
            }
        }
    }
}

#Preview("Trailer View") {
    TrailerView(video: .preview)
        .environment(PlayerModel())
}

#Preview("Trailer Poster View") {
    TrailerPosterView(video: .preview)
}
