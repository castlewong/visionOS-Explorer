/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A group activity to watch a video with others.
*/

import Foundation
import Combine
import GroupActivities
import CoreTransferable
import UIKit

struct VideoWatchingActivity: GroupActivity, Transferable {
    
    // A video to watch.
    let video: Video
    
    // Metadata that the system displays to participants.
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.type = .watchTogether
        metadata.title = video.title
        metadata.previewImage = previewImage
        metadata.fallbackURL = fallbackURL
        metadata.supportsContinuationOnTV = true
        return metadata
    }
    
    var previewImage: CGImage? {
        UIImage(named: video.landscapeImageName)?.cgImage
    }
    
    var fallbackURL: URL? {
        // When working with remote media, specify the media's URL as the fallback.
        video.hasRemoteMedia ? video.resolvedURL : nil
    }
}
