/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that plays the app's sound effects and music.
*/
import AVKit
import RealityKit

/// The kinds of background music that play during different parts of the game.
public enum MusicMode {
    case menu
    case build
    case ride
    
    case silent
    
    var volume: Float {
        switch self {
        case .menu: 0.4
        case .build: 0.4
        case .ride: 0.4
        case .silent: 0.0
        }
    }
}

/// The sound effects available for playing when you take certain actions.
public enum SoundEffect: String, CaseIterable {
    case placePiece = "placePiece"
    case deletePiece = "deletePiece"
    case selectPiece = "pickUp"
    
    case water = "waterFlowing"
    case trapDoor = "startRide"
    case fishDrop = "fishSound_longLoudHappy"
    case fishSlide = "fishSound_mediumHappy"
    case fishGasp = "fishSound_quietHappy"
    case fishSucceed = "endRide"
    
    /// Plays a sound effect from an entity.
    func play(on entity: Entity, offset: Duration? = nil) {
        guard let effect = Self.soundForEffect[self] else {
            fatalError("No sound asset for effect: \(self)")
        }
        
        let audioController = entity.prepareAudio(effect)
        audioController.gain = gain
        
        if !Self.isMuted {
            if let offset = offset {
                audioController.seek(to: offset)
            }
            audioController.play()
            
            let cancellation = {
                audioController.stop()
            }
            
            Self.loopCancellations.append((self, cancellation))
        }
    }
    
    @discardableResult
    func loopingPlay(on entity: Entity) -> () -> Void {
        guard let effect = Self.soundForEffect[self] else {
            fatalError("No sound asset for effect: \(self)")
        }
        
        var shouldLoop = true
        let audioController = entity.prepareAudio(effect)
        audioController.gain = gain
        audioController.completionHandler = {
            if shouldLoop {
                audioController.play()
            }
        }
        
        if !Self.isMuted {
            audioController.play()
        }
        
        let cancellation = {
            shouldLoop = false
            audioController.stop()
        }
        
        Self.loopCancellations.append((self, cancellation))
        
        return cancellation
    }
    
    /// Plays a random sound effect at random time intervals.
    static func randomAmbientPlay(on entity: Entity) {
        var shouldLoop = true
        var audioController: AudioPlaybackController? = nil
        
        func recursiveCompletion() {
            if shouldLoop {
                randomLater {
                    if !shouldLoop {
                        return
                    }
                    
                    let effect: Self = [.fishDrop, .fishSlide, .fishGasp].randomElement()!
                    let newController = entity.prepareAudio(Self.soundForEffect[effect]!)
                    newController.gain = effect.gain
                    if !Self.isMuted {
                        newController.play()
                    }
                    newController.completionHandler = recursiveCompletion
                    audioController = newController
                }
            }
        }
        
        recursiveCompletion()
        
        let cancellation = {
            shouldLoop = false
            audioController?.stop()
        }
        
        Self.loopCancellations.append((.fishDrop, cancellation))
    }
    
    var gain: Double {
        switch self {
        case .placePiece: 400
        case .deletePiece: 220
        case .selectPiece: 400
        case .water: -10
        case .trapDoor: 200
        case .fishDrop: 40
        case .fishSlide: 40
        case .fishGasp: 40
        case .fishSucceed: 200
        }
    }
    
    /// Calls a closure at a random time in the future.
    private static func randomLater(_ perform: @escaping () -> Void) {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 7...11), repeats: false) { timer in
            perform()
        }
    }
    
    @MainActor
    public static func enqueueEffectsForRide(_ appState: AppState, resume: Bool = false) {
        let elapsed = (Date.timeIntervalSinceReferenceDate - appState.rideStartTime)
        
        if resume, elapsed < ambientSoundsDelay {
            Self.trapDoor.play(on: appState.startPiece ?? appState.root, offset: .seconds(elapsed))
        }
        
        let waterStartTime = waterStartDelay - elapsed
        var waterTimer: Timer? = nil
        if waterStartTime >= 0 {
            waterTimer = Timer.scheduledTimer(withTimeInterval: waterStartTime, repeats: false) { _ in
                Task { @MainActor in
                    if appState.phase == .rideRunning, !appState.isVolumeMuted {
                        SoundEffect.water.loopingPlay(on: appState.startPiece ?? appState.root)
                    }
                }
            }
        }
        
        let ambientStartTime = ambientSoundsDelay - elapsed
        var ambientTimer: Timer? = nil
        
        if ambientStartTime >= 0 {
            ambientTimer = Timer.scheduledTimer(withTimeInterval: ambientStartTime, repeats: false) { _ in
                Task { @MainActor in
                    if appState.phase == .rideRunning && !appState.isVolumeMuted {
                        SoundEffect.randomAmbientPlay(on: appState.startPiece ?? appState.root)
                    }
                }
            }
        }
        
        // Potentially cancel these early if the ride is paused or reset.
        loopCancellations.append((.water, {
            waterTimer?.invalidate()
        }))
        
        loopCancellations.append((nil, {
            ambientTimer?.invalidate()
        }))
    }
    
    /// A mapping of sound effect types to their associated audio resource.
    ///
    /// This map is populated during the asset loading phase when the app starts.
    public static var soundForEffect: [SoundEffect: AudioFileResource] = [:]
    public static var loopCancellations: [(effect: SoundEffect?, closure: () -> Void)] = []
    public static var isMuted = false
    
    public static func stopLoops() {
        loopCancellations.forEach { $0.closure() }
        loopCancellations = []
    }
    
    public static func stopLoops(for effect: Self?) {
        loopCancellations.forEach {
            if let effect = effect, $0.effect == effect {
                $0.closure()
            }
            
            if effect == nil, $0.effect == nil {
                $0.closure()
            }
        }
    }
}
