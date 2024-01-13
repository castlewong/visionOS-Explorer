/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents the video detail view in tvOS.
*/

import SwiftUI

struct DetailView: View {
    
    let video: Video
    @Environment(PlayerModel.self) private var player
    @Environment(VideoLibrary.self) private var library
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background image
            Image(video.landscapeImageName)
                .resizable()
                .scaledToFill()
            // Material gradient
            GradientView(style: .thinMaterial, height: 450, startPoint: .top)
            // Video Content
            VStack {
                HStack {
                    Text(video.title)
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .shadow(radius: 10)
                        .padding([.leading, .top], 100)
                    Spacer()
                }
                Spacer()
                WideDetailView(video: video, player: player, library: library)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    NavigationStack {
        DetailView(video: .preview)
            .environment(PlayerModel())
    }
}
