/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An actor that manages the coordinated playback of a video with participants in a group session.
*/

import Foundation
import Combine
import GroupActivities
import AVFoundation

actor VideoWatchingCoordinator {
    
    // Published values that the player, and other UI items, observe.
    @Published private(set) var sharedVideo: Video?
    
    // Combine subscriptions.
    private var subscriptions = Set<AnyCancellable>()
    
    // An object that determines video equality when sharing.
    private let coordinatorDelegate = CoordinatorDelegate()
    // A player object's playback coordinator.
    private var playbackCoordinator: AVPlayerPlaybackCoordinator
    
    init(playbackCoordinator: AVPlayerPlaybackCoordinator) {
        self.playbackCoordinator = playbackCoordinator
        self.playbackCoordinator.delegate = coordinatorDelegate
        Task {
            await startObservingSessions()
        }
    }
    
    private func startObservingSessions() async {
        // Await new sessions to watch video together.
        for await session in VideoWatchingActivity.sessions() {
            
            // Clean up the old session, if it exists.
            cleanUpSession(groupSession)
            
            // Set the app's active group session before joining.
            groupSession = session
            
            let stateListener = Task {
                await self.handleStateChanges(groupSession: session)
            }
            subscriptions.insert(.init { stateListener.cancel() })
            
            // Observe when the local user or a remote participant changes the activity on the GroupSession
            let activityListener = Task {
                await self.handleActivityChanges(groupSession: session)
            }
            subscriptions.insert(.init { activityListener.cancel() })
            
            // Join the session to participate in playback coordination.
            session.join()
        }
    }
    
    private func cleanUpSession(_ session: GroupSession<VideoWatchingActivity>?) {
        // Exit early if session isn't the same instance as the player model's session.
        guard groupSession === session else { return }
        // Leave the session and set the session and video to nil to publish the invalidated state.
        groupSession?.leave()
        groupSession = nil
        sharedVideo = nil
        
        subscriptions.removeAll()
    }
    
    private var groupSession: GroupSession<VideoWatchingActivity>? {
        didSet {
            guard let groupSession else { return }
            // Set the group session on the AVPlayer instances's playback coordinator
            // so it can synchronize playback with other devices.
            playbackCoordinator.coordinateWithSession(groupSession)
        }
    }
    
    private func handleActivityChanges(groupSession: GroupSession<VideoWatchingActivity>) async {
        for await newActivity in groupSession.$activity.values {
            guard groupSession === self.groupSession else { return }
            updateSharedVideo(video: newActivity.video)
        }
    }
    
    private func handleStateChanges(groupSession: GroupSession<VideoWatchingActivity>) async {
        for await newState in groupSession.$state.values {
            if case .invalidated = newState {
                cleanUpSession(groupSession)
            }
        }
    }
    
    /// Updates the `sharedVideo` state for this actor.
    /// - Parameter video: the video to set as shared.
    private func updateSharedVideo(video: Video) {
        coordinatorDelegate.video = video
        // Set the video as the shared video.
        sharedVideo = video
    }
    
    /// Coordinates the playback of this video with others in a group session.
    /// - Parameter video: the video to share
    func coordinatePlayback(of video: Video) async {
        // Exit early if this video is already shared.
        guard video != sharedVideo else { return }

        // Create a new activity for the selected video.
        let activity = VideoWatchingActivity(video: video)
        
        switch await activity.prepareForActivation() {
        case .activationPreferred:
            do {
                // Attempt to activate the new activity.
                _ = try await activity.activate()
            } catch {
                logger.debug("Unable to activate the activity: \(error)")
            }
        case .activationDisabled:
            // A FaceTime session isn't active, or the user prefers to play the
            // video apart from the group. Set the sharedVideo to nil.
            sharedVideo = nil
        default:
            break
        }
    }
    
    /// An implementation of `AVPlayerPlaybackCoordinatorDelegate` that determines how
    /// the playback coordinator identifies local and remote media.
    private class CoordinatorDelegate: NSObject, AVPlayerPlaybackCoordinatorDelegate {
        var video: Video?
        // Adopting this delegate method is required when playing local media,
        // or any time you need a custom strategy for identifying media. Without
        // implementing this method, coordinated playback won't function correctly.
        func playbackCoordinator(_ coordinator: AVPlayerPlaybackCoordinator,
                                 identifierFor playerItem: AVPlayerItem) -> String {
            // Return the video id as the player item identifier.
            "\(video?.id ?? -1)"
        }
    }
}

