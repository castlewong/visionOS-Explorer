/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions to simplify creating previews.
*/

import Foundation

extension Video {
    static var preview: Video {
        VideoLibrary().videos[0]
    }
}

extension Array {
    static var all: [Video] {
        VideoLibrary().videos
    }
}

