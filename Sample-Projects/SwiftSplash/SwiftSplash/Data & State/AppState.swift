/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main application state class.
*/

import ARKit
import AVKit
import Combine
import Foundation
import OSLog
import RealityKit
import SwiftSplashTrackPieces
import SwiftUI
import UIKit

/// This contains one case for each connectable piece except the start and goal pieces, which are handled differently.
public enum TilePieceKey: String, CaseIterable, Codable, Sendable {
    case slide1 = "slide_01" // Straight piece
    case slide2 = "slide_02" // Straight slide down
    case slide3 = "slide_03" // Right 90 turn
    case slide4 = "slide_04" // Left 90 turn
    case slide5 = "slide_05" // Spiral
}

/// The types of connection points a slide piece can have. `.inPoint` can only connect to `.outPoint`, and vice versa.
enum ConnectionPointType {
    case inPoint
    case outPoint
    case noPoint
}

/// Application logger for reporting errors, warnings, and useful information.
let logger = Logger(subsystem: "com.apple-samplecode.SwiftSplash", category: "general")

/// An object that maintains app-wide state.
@Observable
@MainActor
public class AppState {
    
     var phase: AppPhase = .startingUp
        
    /// The app's AR session.
     var session: ARKitSession = ARKitSession()
    
    /// The app uses this to retrieve the location and orientation of the device.
     var worldInfo = WorldTrackingProvider()
    
     var meshEntities = [UUID: ModelEntity]()
     var startAttachment: ViewAttachmentEntity?
     var editAttachment: ViewAttachmentEntity?
     var isImmersiveViewShown = false
    
    /// A Boolean that indicates whether the ride is currently running.
     var isRideRunning = false
    
    /// The time the current ride run started or 0 if the ride isn't running.
    var rideStartTime: TimeInterval = 0
    
    var rideDuration: TimeInterval = 0.0
    
    public var lastConnectedPiece: Entity? {
        var lastPiece: Entity? = nil
        var iteratePiece: Entity? = startPiece

        var seen = [Entity]()
        while iteratePiece != nil {
            guard let thePiece = iteratePiece else { break }

            if seen.contains(thePiece) { break }
            seen.append(thePiece)
            lastPiece = iteratePiece
            if let next = iteratePiece?.connectableStateComponent?.nextPiece {
                if next != placePieceMarker {
                    iteratePiece = iteratePiece?.connectableStateComponent?.nextPiece
                } else {
                    iteratePiece = nil
                }
            } else {
                iteratePiece = nil
            }
        }
        return lastPiece
    }
    
    var presentedRide = [RideDestination]()
    
    /// Stores the track piece that's currently selected and in edit mode. Only one track can be in edit mode at a time, but any number
    /// of additional pieces can be selected and any edit actions apply to them all. There doesn't have to be a  piece in edit mode, but
    /// if no piece is in edit mode, there should be no additional selected track pieces.
    var trackPieceBeingEdited: Entity?

    var isVolumeMuted = false {
        didSet {
            SoundEffect.isMuted = isVolumeMuted
            if isVolumeMuted {
                [buildMusic, menuMusic, rideMusic].forEach { $0.volume = 0 }
                SoundEffect.stopLoops()
            } else {
                [buildMusic, menuMusic, rideMusic].filter { $0.isPlaying }.forEach {
                    $0.volume = 1.0
                }
                
                switch phase {
                case .buildingTrack:
                    ()
                case .rideRunning:
                    ()
                default:
                    ()
                }
            }
        }
    }
    
    /// Indicates whether the ride can be started,
    public var canStartRide: Bool {
        guard let startPiece = startPiece else { fatalError("Start piece is missing.") }
        guard let goalPiece = goalPiece else { fatalError("Goal piece is missing") }
        
        // Goal piece is not in the scene, can't start ride
        if goalPiece.parent == nil { return false }
        
        var iteratePiece: Entity? = startPiece
        var lastPiece: Entity? = nil
        while iteratePiece != nil {
            
            if iteratePiece?.connectableStateComponent?.nextPiece == nil {
                lastPiece = iteratePiece
            }
            iteratePiece = iteratePiece?.connectableStateComponent?.nextPiece
        }
        if lastPiece != goalPiece { return false }
        
        return true
    }
    
    var music: MusicMode = .silent {
        didSet {
            if oldValue == music {
                return
            }
            let playerMap: [MusicMode: AVAudioPlayer] = [
                .build: buildMusic,
                .menu: menuMusic,
                .ride: rideMusic
            ]
            
            let oldPlayer = playerMap[oldValue]
            let newPlayer = playerMap[music]
            
            let crossfade = music == .silent ? 0.0 : 3.0
            
            oldPlayer?.setVolume(0, fadeDuration: crossfade)
            Timer.scheduledTimer(withTimeInterval: crossfade, repeats: false) { timer in
                oldPlayer?.stop()
            }

            if !isVolumeMuted {
                newPlayer?.volume = 0
                newPlayer?.numberOfLoops = -1
                newPlayer?.currentTime = 0
                newPlayer?.play()
                newPlayer?.setVolume(music.volume, fadeDuration: crossfade)
            }
        }
    }
    
    let connectableQuery = EntityQuery(where: .has(ConnectableComponent.self))
    
    /// Stores any additional selected pieces. Any action taken to the piece being edited applies to these as well.
    var additionalSelectedTrackPieces = [Entity]()
    
    /// An array of all the pieces available to place in a scene excluding the start and end pieces.
     public var pieces = [
        Piece(name: "Straight", key: .slide1, sceneName: "Slide01.usda"),
        Piece(name: "Slide", key: .slide2, sceneName: "Slide02.usda"),
        Piece(name: "Right Turn", key: .slide3, sceneName: "Slide03.usda"),
        Piece(name: "Left Turn", key: .slide4, sceneName: "Slide04.usda"),
        Piece(name: "Spiral", key: .slide5, sceneName: "Slide05.usda")
    ]
    init() {
        root.name = "Root"
        Task.detached(priority: .high) {
            
            do {
                try await self.session.run([self.worldInfo])
            } catch {
                logger.error("Error running World Tracking Provider: \(error.localizedDescription)")
            }
            // Load the pieces from the Reality Composer Pro file into memory.
            await self.loadPieces()
            Task { @MainActor in
                guard let goalPiece = self.goalPiece else { return }
                goalPiece.forEachDescendant(withComponent: ParticleEmitterComponent.self) { entity, component in
                    var component = component
                    component.isEmitting = false
                    entity.components[ParticleEmitterComponent.self] = component
                    entity.components.set(component)
                }
            }
        }
        
        // Load sounds.
        Task {
            for effect in SoundEffect.allCases {
                let resource = try await AudioFileResource(named: "\(effect.rawValue).wav")
                SoundEffect.soundForEffect[effect] = resource
            }
        }
    }
    
    // Background music.
    public var buildMusic = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "swiftSplash_BuildMode", withExtension: "wav")!)
    public var menuMusic = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "swiftSplash_Menu", withExtension: "wav")!)
    public var rideMusic = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "swiftSplash_RideMode", withExtension: "m4a")!)
    
    // MARK: - Piece Entities -
    
    /// A dictionary of pieces loaded from the Reality Composer Pro scene. This app
    /// doesn't add the Reality Composer Pro scene to the `RealityView` directly.
    /// Instead, it pulls out each of the root entities and stores them to use
    /// as a template. When adding a new piece, the app clones the template
    /// piece and adds it to the scene.
    var pieceTemplates = [TilePieceKey: Entity]()
    
    /// The root entity for the `RealityView` scene. Storing this in application
    /// state means any code in the app can get access to it.
    public var root = Entity()
    
    /// The piece from which the player starts building the ride.
    public var startPiece: Entity?
    
    /// The last piece of a track. This must be placed to start the ride.
    public var goalPiece: Entity?
    
    /// A special entity that shows where the next track piece will go.
    public var placePieceMarker: Entity?
    
    /// The current material selection. This is used when adding a track piece. It
    /// also updates the button image file names to reflect the current material selection.
    public var selectedMaterialIndex: Int = MaterialType.metal.rawValue
    
    /// These hold the button image filenames. They're updated whenever the material index changes so the UI
    /// always shows the track piece buttons with the correct material applied.
    public var simpleRampImageName: String {
        "slide_01_\(selectedMaterialType.name)"
    }
    public var slideImageName: String {
        "slide_02_\(selectedMaterialType.name)"
    }
    public var rightTurnImageName: String {
        "slide_03_\(selectedMaterialType.name)"
    }
    public var leftTurnImageName: String {
        "slide_05_\(selectedMaterialType.name)"
    }
    public var spiralImageName: String {
        "slide_04_\(selectedMaterialType.name)"
    }
    public var goalImageNamne: String {
        "goal_\(selectedMaterialType.name)"
    }
    
    /// A convenience accessor to get the `MaterialType` corresponding to the current selected material index.
    public var selectedMaterialType: MaterialType {
        get {
            return MaterialType(rawValue: selectedMaterialIndex) ?? .metal
        } set {
            selectedMaterialIndex = newValue.rawValue
        }
    }
}

@MainActor
struct RideDestination: Identifiable, Hashable {
    let id = "ride"
}
