/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays a list of movies related to the currently playing content.
*/

import SwiftUI

struct UpNextView: View {
    
    let title = "Up Next"
    
    let videos: [Video]
    let model: PlayerModel
    
    var body: some View {
        VideoListView(videos: videos, cardStyle: .compact, cardSpacing: isTV ? 50 : 30) { video in
            model.loadVideo(video, presentation: .fullScreen)
        }
    }
}

#Preview {
    UpNextView(videos: .all, model: PlayerModel())
        .padding()
}
