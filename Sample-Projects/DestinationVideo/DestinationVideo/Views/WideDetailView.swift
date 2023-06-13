/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that display video detail in a wide layout.
*/

import SwiftUI

/// A view that displays action controls and video detail in a horizontal layout.
///
/// The detail view in iPadOS and tvOS use this view to display the video information.
struct WideDetailView: View {
    
    let video: Video
    let player: PlayerModel
    let library: VideoLibrary
    
    var body: some View {
        // Arrange the content in a horizontal layout.
        HStack(alignment: .top, spacing: isTV ? 40 : 20) {
            VStack {
                // A button that plays the video in a full-screen presentation.
                Button {
                    /// Load the media item for full-screen presentation.
                    player.loadVideo(video, presentation: .fullScreen)
                } label: {
                    Label("Play Video", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                // A button to toggle whether the video is in the user's Up Next queue.
                Button {
                    // Calling this method toggles the video's inclusion state in the Up Next queue.
                    library.toggleUpNextState(for: video)
                } label: {
                    let isUpNext = library.isVideoInUpNext(video)
                    Label(isUpNext ? "In Up Next" : "Add to Up Next",
                          systemImage: isUpNext ? "checkmark" : "plus")
                            .frame(maxWidth: .infinity)

                }
            }
            .fontWeight(.semibold)
            .foregroundStyle(.black)
            .buttonStyle(.borderedProminent)
            .frame(width: isTV ? 400 : 200)
            // Make the buttons the same width.
            .fixedSize(horizontal: true, vertical: false)
            
            Text(video.description)
            
            VStack(alignment: .leading, spacing: 4) {
                RoleView(role: "Stars", people: video.info.stars)
                RoleView(role: "Director", people: video.info.directors)
                RoleView(role: "Writers", people: video.info.writers)
            }
            
        }
        .frame(height: isTV ? 300 : 150)
        .padding([.leading, .trailing], isTV ? 80 : 40)
        .padding(.bottom, 20)
    }
}

