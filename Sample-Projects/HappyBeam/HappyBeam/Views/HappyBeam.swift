/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view.
*/

import Combine
import SwiftUI
@preconcurrency import GroupActivities
import RealityKit

struct HappyBeam: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @EnvironmentObject var gameModel: GameModel
    
    @State var session: GroupSession<HeartProjection>? = nil
    @State var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var subscriptions = Set<AnyCancellable>()
    
    var body: some View {
        let gameState = GameScreen.from(state: gameModel)
        VStack {
            Spacer()
            Group {
                switch gameState {
                case .start:
                    Start()
                case .soloPlay:
                    SoloPlay()
                case .lobby:
                    Lobby()
                case .soloScore:
                    SoloScore()
                case .multiPlay:
                    MultiPlay()
                case .multiScore:
                    MultiScore()
                }
            }
            .glassBackgroundEffect(
                in: RoundedRectangle(
                    cornerRadius: 32,
                    style: .continuous
                )
            )
        }
        
        .onReceive(timer) { _ in
            if (gameModel.isPlaying && gameModel.isSoloReady) || (gameModel.isSharePlaying && gameModel.players.allSatisfy({ $0.isReady })) {
                if gameModel.timeLeft > 0 && !gameModel.isPaused {
                    gameModel.timeLeft -= 1
                    if (gameModel.timeLeft % 5 == 0 || gameModel.timeLeft == GameModel.gameTime - 1) && gameModel.timeLeft > 4 {
                        Task { @MainActor () -> Void in
                            do {
                                let spawnAmount = 3
                                for _ in (0..<spawnAmount) {
                                    _ = try await spawnCloud()
                                    try await Task.sleep(for: .milliseconds(300))
                                }
                                
                                postCloudOverviewAnnouncement(gameModel: gameModel)
                            } catch {
                                print("Error spawning a cloud:", error)
                            }
                            
                        }
                    }
                } else if gameModel.timeLeft == 0 {
                    print("Game finished.")
                    gameModel.isFinished = true
                    gameModel.timeLeft = -1
                }
            }
            
            if gameModel.isCountDownReady && gameModel.countDown > 0 {
                var attrStr = AttributedString("\(gameModel.countDown)")
                attrStr.accessibilitySpeechAnnouncementPriority = .high
                AccessibilityNotification.Announcement("\(gameModel.countDown)").post()
                gameModel.countDown -= 1
            } else if gameModel.countDown == 0 {
                gameModel.isSoloReady = true
                Task {
                    await openImmersiveSpace(id: "happyBeam")
                }
                gameModel.countDown = -1
            }
        }
        .task {
            sessionInfo = .init()
            for await newSession in HeartProjection.sessions() {
                print("New GroupActivities session", newSession)

                session = newSession
                sessionInfo?.session = newSession
                gameModel.isSharePlaying = true
                
                // Spatial coordination.
                if let coordinator = await newSession.systemCoordinator {
                    var config = SystemCoordinator.Configuration()
                    config.spatialTemplatePreference = .sideBySide
                    config.supportsGroupImmersiveSpace = true
                    coordinator.configuration = config
                    
                    Task.detached { @MainActor in
                        for await state in coordinator.localParticipantStates {
                            if state.isSpatial {
                                gameModel.isSpatial = true
                            } else {
                                gameModel.isSpatial = false
                            }
                        }
                    }
                }
                
                do {
                    print("Waiting before starting group activity.")
                    try await Task.sleep(for: .seconds(3))
                } catch {
                    print("Couldn't sleep.", error)
                }
                
                gameModel.players = newSession.activeParticipants.map { participant in
                    Player(name: String(participant.id.asPlayerName), score: 0, color: .random())
                }
                
                Player.local = gameModel.players.first(where: { $0.name == newSession.localParticipant.id.asPlayerName })
                
                // Add beams for players who aren't the `local` player.
                gameModel.players.filter { $0.name != Player.local!.name }.forEach { player in
                    Task {
                        multiBeamMap[player.name] = await initialBeam(for: player)
                    }
                }
                
                Task {
                    for try await updatedPlayerList in newSession.$activeParticipants.values {
                        for participant in updatedPlayerList {
                            Player.local = gameModel.players.first(where: { $0.name == newSession.localParticipant.id.asPlayerName })
                            let potentialNewPlayer = Player(name: String(participant.id.asPlayerName), score: 0, color: .random())
                            if !gameModel.players.contains(where: { $0.name == potentialNewPlayer.name }) {
                                gameModel.players.append(potentialNewPlayer)
                                
                                Task {
                                    multiBeamMap[potentialNewPlayer.name] = await initialBeam(for: potentialNewPlayer)
                                }
                            }
                        }
                    }
                }
                
                await openImmersiveSpace(id: "happyBeam")
                
                sessionInfo?.messenger = GroupSessionMessenger(session: newSession, deliveryMode: .unreliable)
                sessionInfo?.reliableMessenger = GroupSessionMessenger(session: newSession, deliveryMode: .reliable)
                
                newSession.join()
                
                newSession.$state.sink { state in
                    if case .invalidated = state {
                        gameModel.reset()
                        sessionInfo = nil
                    }
                }
                .store(in: &subscriptions)
                
                // Handle remote scores in multiplayer.
                Task {
                    for await (message, sender) in sessionInfo!.reliableMessenger!.messages(of: ScoreMessage.self) {
                        gameModel.clouds[message.cloudID].isHappy = true
                        gameModel
                            .players
                            .first(where: { $0.name == sender.source.id.asPlayerName })!
                            .score += 1
                        
                        print("Adding a score to player ", gameModel.players.first(where: { $0.name == sender.source.id.asPlayerName })!.name)
                        
                        // Show remote score.
                        try handleCloudHit(for: cloudEntities[message.cloudID], gameModel: gameModel, remote: true)
                    }
                }
                
                // Handle ready messages in multiplayer.
                Task {
                    for await (message, sender) in sessionInfo!.reliableMessenger!.messages(of: ReadyStateMessage.self) where message.ready {
                        gameModel
                            .players
                            .first(where: { $0.name == sender.source.id.asPlayerName })!
                            .isReady = true
                        
                        print("A player is ready:", gameModel.players.first(where: { $0.name == sender.source.id.asPlayerName })!.name)
                    }
                }
                
                // Handle the display of multiple beams in multiplayer.
                Task {
                    for await (message, sender) in sessionInfo!.messenger!.messages(of: BeamMessage.self) {
                        guard let multiplayerBeam = multiBeamMap[sender.source.id.asPlayerName] else {
                            print("Got beam message for a beam that doesn't exist:", sender.source.id.asPlayerName)
                            continue
                        }
                        
                        multiplayerBeam.transform = Transform(matrix: simd_float4x4(message.pose))
                    }
                }
            }
        }
    }
}

#Preview {
    HappyBeam()
        .environmentObject(GameModel())
}

extension UUID {
    var asPlayerName: String {
        String(uuidString.split(separator: "-").last!)
    }
}

enum GameScreen {
    static func from(state: GameModel) -> Self {
        if !state.isPlaying && !state.isSharePlaying {
            return .start
        } else if state.isPlaying {
            if !state.isFinished {
                if !state.isSoloReady {
                    return .lobby
                } else {
                    return .soloPlay
                }
            } else {
                return .soloScore
            }
        } else if state.isSharePlaying {
            if !state.players.allSatisfy({ $0.isReady }) {
                return .lobby
            }
            if !state.isFinished {
                return .multiPlay
            } else {
                return .multiScore
            }
        }
        
        return .start
    }
    
    case start
    case soloPlay
    case soloScore
    case lobby
    case multiPlay
    case multiScore
}

