/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays information about a video like its title, actors, and rating.
*/
import SwiftUI

struct VideoInfoView: View {
    let video: Video
    var body: some View {
        VStack(alignment: .leading) {
            Text(video.title)
                .font(isVision ? .title : .title2)
                .padding(.bottom, 4)
            InfoLineView(year: video.info.releaseYear,
                         rating: video.info.contentRating,
                         duration: video.info.duration)
                .padding([.bottom], 4)
            GenreView(genres: video.info.genres)
                .padding(.bottom, 4)
            RoleView(role: String(localized: "Stars"), people: video.info.stars)
                .padding(.top, 1)
            RoleView(role: String(localized: "Director"), people: video.info.directors)
                .padding(.top, 1)
            RoleView(role: String(localized: "Writers"), people: video.info.writers)
                .padding(.top, 1)
                .padding(.bottom, 12)
            Text(video.description)
                .font(.headline)
                .padding(.bottom, 12)
        }
    }
}

/// A view that displays a horizontal list of the video's year, rating, and duration.
struct InfoLineView: View {
    let year: String
    let rating: String
    let duration: String
    var body: some View {
        HStack {
            Text("\(year) | \(rating) | \(duration)")
                .font(isTV ? .caption : .subheadline.weight(.medium))
        }
    }
}

/// A view that displays a comma-separated list of genres for a video.
struct GenreView: View {
    let genres: [String]
    var body: some View {
        HStack(spacing: 8) {
            ForEach(genres, id: \.self) {
                Text($0)
                    .fixedSize()
                #if os(xrOS)
                    .font(.caption2.weight(.bold))
                #else
                    .font(.caption)
                #endif
                    .padding([.leading, .trailing], isTV ? 8: 4)
                    .padding([.top, .bottom], 4)
                    .background(RoundedRectangle(cornerRadius: 5).stroke())
                    .foregroundStyle(.secondary)
            }
            // Push the list to the leading edge.
            Spacer()
        }
    }
}

/// A view that displays a name of a role, followed by one or more people who hold the position.
struct RoleView: View {
    let role: String
    let people: [String]
    var body: some View {
        VStack(alignment: .leading) {
            Text(role)
            Text(people.formatted())
                .foregroundStyle(.secondary)
        }
    }
}

#if os(xrOS)
#Preview {
    VideoInfoView(video: .preview)
        .padding()
        .frame(width: 500, height: 500)
        .background(.gray)
        .previewLayout(.sizeThatFits)
}
#endif
