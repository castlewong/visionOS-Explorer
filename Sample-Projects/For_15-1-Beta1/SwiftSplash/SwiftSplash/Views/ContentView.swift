/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main SwiftUI view.
*/

import SwiftUI
import RealityKit
/// The app's main view.
struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.scenePhase) private var scenePhase
    
    private let lightGrayTextColor = Color(white: 0.84)
    @State private var countDown: CFAbsoluteTime = -1.0
    @State private var confirmationShown = false
    @State private var isReducedHeight = false
    
    var body: some View {
        @Bindable var appState = appState
        switch appState.phase {
            case .startingUp, .waitingToStart, .loadingAssets, .placingStartPiece, .draggingStartPiece:
                Spacer()
                SplashScreenView()
                    .onAppear {
                        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                            return
                        }
                        
                        windowScene.requestGeometryUpdate(.Vision(resizingRestrictions: UIWindowScene.ResizingRestrictions.none))
                    }
                    .glassBackgroundEffect()
            case .buildingTrack, .rideRunning:
                Spacer()
                NavigationStack(path: $appState.presentedRide) {
                    PieceShelfView()
                        .transition(.opacity)
                        .navigationTitle("Build")
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationDestination(for: RideDestination.self) { ride in
                            RideControlView()
                                .transition(.opacity)
                                .navigationTitle("Ride")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    Button {
                                        appState.isVolumeMuted.toggle()
                                    } label: {
                                        Label {
                                            if appState.isVolumeMuted {
                                                Text("Unmute")
                                            } else {
                                                Text("Mute")
                                            }
                                        } icon: {
                                            if appState.isVolumeMuted {
                                                Image(systemName: "speaker.slash.fill")
                                            } else {
                                                Image(systemName: "speaker.wave.3.fill")
                                            }
                                        }
                                        .animation(.none, value: 0)
                                        .fontWeight(.semibold)
                                        .frame(width: 100)
                                    }
                                }
                                .toolbar(.visible, for: .navigationBar)
                                .toolbarRole(.navigationStack)
                        }
                        .toolbar {
                            Button(role: .destructive) {
                                confirmationShown = true
                            } label: {
                                Label("Delete ride", systemImage: "trash.fill")
                            }
                            .confirmationDialog(
                                "Are you sure you want to delete all pieces and start over?",
                                isPresented: $confirmationShown,
                                titleVisibility: .visible
                            ) {
                                Text("Are you sure you want to delete all pieces and start over?")
                                Button("Delete ride", role: .destructive) {
                                    withAnimation {
                                        appState.resetBoard()
                                    }
                                }
                                Button("Continue editing", role: .cancel) {
                                }
                            }
                            
                            Button {
                                if appState.trackPieceBeingEdited == nil {
                                    appState.trackPieceBeingEdited = appState.startPiece
                                    appState.trackPieceBeingEdited?.connectableStateComponent?.isSelected = true
                                    if let editMenu = appState.editAttachment {
                                        if editMenu.parent != nil {
                                            editMenu.removeFromParent()
                                        }
                                        appState.startPiece?.uiAnchor?.addChild(editMenu)
                                    }
                                }
                                
                                appState.updateConnections()
                                appState.updateSelection()
                                appState.selectAll()
                            } label: {
                                Label("Select All", systemImage: "plus.square.dashed")
                            }
                            
                            Button {
                                appState.isVolumeMuted.toggle()
                            } label: {
                                Label {
                                    if appState.isVolumeMuted {
                                        Text("Unmute")
                                    } else {
                                        Text("Mute")
                                    }
                                } icon: {
                                    if appState.isVolumeMuted {
                                        Image(systemName: "speaker.slash.fill")
                                    } else {
                                        Image(systemName: "speaker.wave.3.fill")
                                    }
                                }
                                .animation(.none, value: 0)
                                .fontWeight(.semibold)
                                .frame(width: 100)
                            }
                        }
                        .toolbar(.visible, for: .navigationBar)
                        .onChange(of: appState.trackPieceBeingEdited) { _, trackPieceBeingEdited in
                            guard let trackPieceBeingEdited = trackPieceBeingEdited else { return }
                            trackPieceBeingEdited.connectableStateComponent?.isSelected = true
                            appState.updateSelection()
                        }

                }
                .frame(width: 460, height: !isReducedHeight ? 540 : 200)

                // If someone closes the main window, dismiss the immersive space. If placing the first piece, ignore it.
                .onChange(of: scenePhase) { _, newPhase in
                    Task {
                        if (newPhase == .background || newPhase == .inactive) && appState.isImmersiveViewShown
                            && appState.phase != .placingStartPiece && appState.phase != .draggingStartPiece {
                            appState.resetBoard()
                            appState.goBackToWaiting()
                            await dismissImmersiveSpace()
                            appState.isImmersiveViewShown = false
                        }
                    }
                }
                .onChange(of: appState.presentedRide) {
                    if appState.presentedRide.isEmpty {
                        withAnimation {
                            // Went back.
                            shouldCancelRide = true
                            appState.resetRideAnimations()
                            appState.goalPiece?.stopWaterfall()
                            appState.returnToBuildingTrack()
                            appState.isRideRunning = false
                            appState.music = .build
                            SoundEffect.stopLoops()
                            appState.updateConnections()
                            appState.updateSelection()
                            appState.goalPiece?.setAllParticleEmittersTo(to: false)
                        }
                    } else {
                        // Play.
                        shouldCancelRide = false
                    }
                    
                    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                        Task {
                            withAnimation(.easeIn(duration: 1.0)) {
                                if appState.presentedRide.isEmpty {
                                    isReducedHeight = false
                                } else {
                                    isReducedHeight = true
                                }
                            }
                        }
                    }
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
