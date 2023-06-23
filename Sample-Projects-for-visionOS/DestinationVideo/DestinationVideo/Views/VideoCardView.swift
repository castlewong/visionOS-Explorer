/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that represents a video in the library.
*/
import SwiftUI

/// Constants that represent the supported styles for video cards.
enum VideoCardStyle {
    
    /// A full video card style.
    ///
    /// This style presents a poster image on top and information about the video
    /// below, including video description and genres.
    case full

    /// A style for cards in the Up Next list.
    ///
    /// This style presents a medium-sized poster image on top and a title string below.
    case upNext
    
    /// A compact video card style.
    ///
    /// This style presents a compact-sized poster image on top and a title string below.
    case compact
    
    var cornerRadius: Double {
        switch self {
        case .full:
            #if os(tvOS)
            12.0
            #else
            20.0
            #endif
            
        case .upNext: 12.0
        case .compact: 10.0
        }
    }

}

/// A view that represents a video in the library.
///
/// A user can select a video card to view the video details.
struct VideoCardView: View {
    
    let video: Video
    let style: VideoCardStyle
    let cornerRadius = 20.0
    
    /// Creates a video card view with a video and an optional style.
    ///
    /// The default style is `.full`.
    init(video: Video, style: VideoCardStyle = .full) {
        self.video = video
        self.style = style
    }
    
    var image: some View {
        Image(video.landscapeImageName)
            .resizable()
            .scaledToFill()
    }

    var body: some View {
        switch style {
        case .compact:
            posterCard
                .frame(width: valueFor(iOS: 0, tvOS: 400, visionOS: 200))
        case .upNext:
            posterCard
                .frame(width: valueFor(iOS: 250, tvOS: 500, visionOS: 360))
        case .full:
            VStack {
                image
                VStack(alignment: .leading) {
                    InfoLineView(year: video.info.releaseYear,
                                 rating: video.info.contentRating,
                                 duration: video.info.duration)
                    .foregroundStyle(.secondary)
                    .padding(.top, -10)
                    //.padding(.bottom, 3)
                    Text(video.title)
                        .font(isTV ? .title3 : .title)
                        //.padding(.bottom, 2)
                    Text(video.description)
                    #if os(tvOS)
                        .font(.callout)
                    #endif
                        .lineLimit(2)
                    Spacer()
                    HStack {
                        GenreView(genres: video.info.genres)
                    }
                }
                .padding(20)
            }
            .background(.thinMaterial)
            #if os(tvOS)
            .frame(width: 550, height: 590)
            #else
            .frame(width: isVision ? 395 : 300)
            .shadow(radius: 5)
            .hoverEffect()
            #endif
            .cornerRadius(style.cornerRadius)
        }
    }
    
    @ViewBuilder
    var posterCard: some View {
        #if os(tvOS)
        ZStack(alignment: .bottom) {
            image
            // Material gradient
            GradientView(style: .ultraThinMaterial, height: 90, startPoint: .top)
            Text(video.title)
                .font(.caption.bold())
                .padding()
        }
        .cornerRadius(style.cornerRadius)
        #else
        VStack {
            image
                .cornerRadius(style.cornerRadius)
            Text(video.title)
                .font(isVision ? .title3 : .headline)
                .lineLimit(1)
        }
        .hoverEffect()
        #endif
    }
}
