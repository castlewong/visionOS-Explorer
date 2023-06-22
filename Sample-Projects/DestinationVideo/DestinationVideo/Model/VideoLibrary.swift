/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's video library.
*/

import Foundation
import SwiftUI
import Observation

/// An object that manages the app's video content.
///
/// The app puts an instance of this class into the environment so it can retrieve and
/// update the state of video content in the library.
@Observable class VideoLibrary {
    
    private(set) var videos = [Video]()
    private(set) var upNext = [Video]()
    
    // A URL within the user's Documents directory to which to write their Up Next entries.
    private let upNextURL = URL.documentsDirectory.appendingPathComponent("UpNext.json")
    
    init() {
        // Load all videos available in the library.
        videos = loadVideos()
        // The first time the app launches, set the last three videos as the default Up Next items.
        upNext = loadUpNextVideos(default: Array(videos.suffix(3)))
    }
    
    /// Toggles whether the video exists in the Up Next queue.
    /// - Parameter video: the video to update
    func toggleUpNextState(for video: Video) {
        if !upNext.contains(video) {
            // Insert the video at the beginning of the list.
            upNext.insert(video, at: 0)
        } else {
            // Remove the entry with the matching identifier.
            upNext.removeAll(where: { $0.id == video.id })
        }
        // Persist the Up Next state to disk.
        saveUpNext()
    }
    
    /// Returns a Boolean value that indicates whether the video exits in the Up Next list.
    /// - Parameter video: the video to test,
    /// - Returns: `true` if the item is in the Up Next list; otherwise, `false`.
    func isVideoInUpNext(_ video: Video) -> Bool {
        upNext.contains(video)
    }
    
    /// Finds the items to display in the video player's Up Next list.
    func findUpNext(for video: Video) -> [Video] {
        upNext.filter { $0.id != video.id }
    }
    
    /// Finds the next video in the Up Next list after the current video.
    /// - Parameter video: the current video
    /// - Returns: the next video, or `nil` if none exists.
    func findVideoInUpNext(after video: Video) -> Video? {
        switch upNext.count {
        case 0:
            // Up Next is empty. Return nil.
            return nil
        case 1:
            // The passed in video is the only item in `upNext`, return nil.
            if upNext.first == video {
                return nil
            } else {
                // Return the only item.
                return upNext.first
            }
        default:
            // Find the index of the passed in video. If the video isn't in `upNext`, start at the first item.
            let videoIndex = upNext.firstIndex(of: video) ?? 0
            if videoIndex < upNext.count - 1 {
                return upNext[videoIndex + 1]
            }
            return upNext[0]
        }
    }
    
    /// Loads the video content for the app.
    private func loadVideos() -> [Video] {
        let filename = "Videos.json"
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
            fatalError("Couldn't find \(filename) in main bundle.")
        }
        return load(url)
    }
    
    /// Loads the user's list of videos in their Up Next list.
    private func loadUpNextVideos(`default` defaultVideos: [Video]) -> [Video] {
        // If this file doesn't exist, create it.
        if !FileManager.default.fileExists(atPath: upNextURL.path) {
            // Create an initial file with a default value.
            if !FileManager.default.createFile(atPath: upNextURL.path, contents: "\(defaultVideos.map { $0.id })".data(using: .utf8)) {
                fatalError("Couldn't initialize Up Next store.")
            }
        }
        // Load the ids of the videos in the list.
        let ids: [Int] = load(upNextURL)
        return videos.filter { ids.contains($0.id) }
    }
    
    /// Saves the Up Next data to disk.
    ///
    /// The app saves the state using simple JSON persistence.
    private func saveUpNext() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            // Persist the ids only.
            let data = try encoder.encode(upNext.map { $0.id })
            try data.write(to: upNextURL)
        } catch {
            logger.error("Unable to save JSON data.")
        }
    }
    
    private func load<T: Decodable>(_ url: URL, as type: T.Type = T.self) -> T {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            fatalError("Couldn't load \(url.path):\n\(error)")
        }
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("Couldn't parse \(url.lastPathComponent) as \(T.self):\n\(error)")
        }
    }
}
