/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents the video detail view in iOS.
*/

import SwiftUI

struct DetailView: View {
    
    let video: Video
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(PlayerModel.self) private var player
    @Environment(VideoLibrary.self) private var library
    
    var body: some View {
        GeometryReader() { geometry in
            ZStack(alignment: .bottom) {
                // The background view and gradient.
                Group {
                    // Show a geometry-appropriate background image.
                    backgroundImage(for: geometry)
                    // The gradient overlay view.
                    gradientOverlay
                }
                .ignoresSafeArea()
                // The compact width video info layout.
                if horizontalSizeClass == .compact {
                    VStack {
                        Text(video.title)
                            .font(.title.weight(.semibold))
                        InfoLineView(year: video.info.releaseYear,
                                     rating: video.info.contentRating,
                                     duration: video.info.duration)
                        Button {
                            /// Load the media item for full-screen presentation.
                            player.loadVideo(video, presentation: .fullScreen)
                        } label: {
                            Label("Play Video", systemImage: "play.fill")
                                .fontWeight(.semibold)
                                .foregroundStyle(.black)
                        }
                        .buttonStyle(.borderedProminent)
                        Text(video.description)
                            .padding()
                    }
                    
                } else {
                    // The regular width video info layout.
                    VStack {
                        Text(video.title)
                            .font(.largeTitle).bold()
                        // iPadOS and tvOS share this view to present the video detail information.
                        WideDetailView(video: video, player: player, library: library)
                    }
                }
            }
        }
        // Don't show a navigation title in iOS.
        .navigationTitle("")
    }
    
    /// Returns a background image appropriate for the specified geometry.
    ///
    /// - Parameter geometry: a geometry proxy to use for the calculation.
    /// - Returns: A resizable image appropriate for the current geometry.
    func backgroundImage(for geometry: GeometryProxy) -> Image {
        let usePortrait = geometry.size.height > geometry.size.width
        return Image(usePortrait ? video.portraitImageName : video.landscapeImageName).resizable()
    }
    
    var gradientOverlay: some View {
        VStack {
            // Add a subtle gradient at the top to make the back button stand out.
            GradientView(style: .black.opacity(0.2), height: 120, startPoint: .bottom)
            Spacer()
            // Add a material gradient at bottom to show below the video's detail information.
            GradientView(style: .thinMaterial, height: 400, startPoint: .top)
        }
    }
}

#Preview {
    NavigationStack {
        DetailView(video: .preview)
            .environment(PlayerModel())
    }
}
