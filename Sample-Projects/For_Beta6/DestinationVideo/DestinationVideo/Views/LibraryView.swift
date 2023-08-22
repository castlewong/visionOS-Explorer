/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the list of videos the library contains.
*/
import SwiftUI

/// A view that presents the app's content library.
///
/// This view provides the app's main user interface. It displays two
/// horizontally scrolling rows of videos. The top row displays full-sized
/// cards that represent the Featured videos in the app. The bottom row
/// displays videos that the user adds to their Up Next queue.
///
struct LibraryView: View {
    
    @Environment(PlayerModel.self) private var model
    @Environment(VideoLibrary.self) private var library
    
    /// A path that represents the user's content navigation path.
    @Binding private var navigationPath: [Video]
    /// A path that represents the user's content navigation path.
    @Binding private var isPresentingSpace: Bool
    
    /// Creates a `LibraryView` with a binding to a selection path.
    ///
    /// The default value is an empty binding.
    init(path: Binding<[Video]>, isPresentingSpace: Binding<Bool> = .constant(false)) {
        _navigationPath = path
        _isPresentingSpace = isPresentingSpace
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            // Wrap the content in a vertically scrolling view.
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: verticalPadding) {
                    // Displays the Destination Video logo image.
                    Image("dv_logo")
                        .resizable()
                        .scaledToFit()
                        .padding(.leading, outerPadding)
                        .padding(.bottom, isMobile ? 0 : 8)
                        .frame(height: logoHeight)
                    
                    // Displays a horizontally scrolling list of Featured videos.
                    VideoListView(title: "Featured",
                                  videos: library.videos,
                                  cardStyle: .full,
                                  cardSpacing: horizontalSpacing)
                    
                    // Displays a horizontally scrolling list of videos in the user's Up Next queue.
                    VideoListView(title: "Up Next",
                                  videos: library.upNext,
                                  cardStyle: .upNext,
                                  cardSpacing: horizontalSpacing)
                }
                .padding([.top, .bottom], verticalPadding)
                .navigationDestination(for: Video.self) { video in
                    DetailView(video: video)
                        .navigationTitle(video.title)
                        .navigationBarHidden(isTV)
                }
            }
            #if os(tvOS)
            .ignoresSafeArea()
            #endif
        }
        #if os(xrOS)
        // A custom view modifier that presents an immersive space when you navigate to the detail view.
        .updateImmersionOnChange(of: $navigationPath, isPresentingSpace: $isPresentingSpace)
        #endif
    }

    // MARK: - Platform-specific metrics.
    
    /// The vertical padding between views.
    var verticalPadding: Double {
        valueFor(iOS: 30, tvOS: 40, visionOS: 30)
    }
    
    var outerPadding: Double {
        valueFor(iOS: 20, tvOS: 50, visionOS: 30)
    }
    
    var horizontalSpacing: Double {
        valueFor(iOS: 20, tvOS: 80, visionOS: 30)
    }
    
    var logoHeight: Double {
        valueFor(iOS: 24, tvOS: 60, visionOS: 34)
    }
}

#Preview {
    NavigationStack {
        LibraryView(path: .constant([]))
    }
}
