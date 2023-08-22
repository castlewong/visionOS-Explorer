/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A list of video cards.
*/

import SwiftUI

/// A view the presents a horizontally scrollable list of video cards.
struct VideoListView: View {
    
    typealias SelectionAction = (Video) -> Void

    private let title: String?
    private let videos: [Video]
    private let cardStyle: VideoCardStyle
    private let cardSpacing: Double

    private let selectionAction: SelectionAction?
    
    /// Creates a view to display the specified list of videos.
    /// - Parameters:
    ///   - title: An optional title to display above the list.
    ///   - videos: The list of videos to display.
    ///   - cardStyle: The style for the video cards.
    ///   - cardSpacing: The spacing between cards.
    ///   - selectionAction: An optional action that you can specify to directly handle the card selection.
    ///    When the app doesn't specify a selection action, the view presents the card as a `NavigationLink.
    init(title: String? = nil, videos: [Video], cardStyle: VideoCardStyle, cardSpacing: Double, selectionAction: SelectionAction? = nil) {
        self.title = title
        self.videos = videos
        self.cardStyle = cardStyle
        self.cardSpacing = cardSpacing
        self.selectionAction = selectionAction
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleView
                .padding(.leading, margins)
                .padding(.bottom, valueFor(iOS: 8, tvOS: -40, visionOS: 12))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: cardSpacing) {
                    ForEach(videos) { video in
                        // If the app initializes the view with a selection action closure,
                        // display a video card button that calls it.
                        if let selectionAction {
                            Button {
                                selectionAction(video)
                            } label: {
                                VideoCardView(video: video, style: cardStyle)
                            }
                        }
                        // Otherwise, create a navigation link.
                        else {
                            NavigationLink(value: video) {
                                VideoCardView(video: video, style: cardStyle)
                            }
                        }
                    }
                }
                .buttonStyle(buttonStyle)
                // In tvOS, add vertical padding to accomodate card resizing.
                .padding([.top, .bottom], isTV ? 60 : 0)
                .padding([.leading, .trailing], margins)
            }
        }
    }
    
    @ViewBuilder
    var titleView: some View {
        if let title {
            Text(title)
            #if os(xrOS)
                .font(cardStyle == .full ? .largeTitle : .title)
            #elseif os(tvOS)
                .font(cardStyle == .full ? .largeTitle.weight(.semibold) : .title2)
            #else
                .font(cardStyle == .full ? .title2.bold() : .title3.bold())
            #endif
            
        }
    }
    
    var buttonStyle: some PrimitiveButtonStyle {
        #if os(tvOS)
        .card
        #else
        .plain
        #endif
    }
    
    var margins: Double {
        valueFor(iOS: 20, tvOS: 50, visionOS: 30)
    }
}

#Preview("Full") {
    NavigationStack {
        VideoListView(title: "Featured", videos: .all, cardStyle: .full, cardSpacing: 80)
            .frame(height: 380)
    }
}

#Preview("Up Next") {
    NavigationStack {
        VideoListView(title: "Up Next", videos: .all, cardStyle: .upNext, cardSpacing: 20)
            .frame(height: 200)
    }
}

#Preview("Compact") {
    NavigationStack {
        VideoListView(videos: .all, cardStyle: .compact, cardSpacing: 20)
            .padding()
    }
}
