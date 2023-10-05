/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main SwiftUI view when building the ride.
*/

import CoreGraphics
import SwiftUI
import SwiftSplashTrackPieces
/// A UI element containing the various pieces the player can add to the track.
struct PieceShelfView: View {
    @Environment(AppState.self) var appState
    @Environment(\.dismiss) private var dismiss
    @State private var showStartOverConfirmation = false
    @State private var animateIn = true
    @State private var canStartRide = false
    
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    static var displayedOnce = false

    var body: some View {
        @Bindable var appState = appState
        
        VStack {
            Picker("Material", selection: $appState.selectedMaterialIndex) {
                Text("Metal")
                    .tag(MaterialType.metal.rawValue)
                Text("Wood")
                    .tag(MaterialType.wood.rawValue)
                Text("Plastic")
                    .tag(MaterialType.plastic.rawValue)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 25)
            .padding(.bottom)
            
            PieceShelfTrackButtonsView()
            
            Button {
                appState.startRide()
                appState.presentedRide = [.init()]
            } label: {
                Label("Start Ride", systemImage: "play.fill")
            }
            .disabled(!canStartRide)
            .controlSize(.large)
            .padding(.top)
            .onChange(of: appState.phase) { _, newPhase in
                if newPhase != .buildingTrack && newPhase != .rideRunning {
                    dismiss()
                }
            }
        }
        .opacity(animateIn ? 0 : 1.0)
        .frame(width: 460, height: 420, alignment: .center)
        .onAppear {
            if Self.displayedOnce {
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                    withAnimation(.easeIn(duration: 0.7)) {
                        animateIn = false
                    }
                }
            } else {
                animateIn = false
            }
            
            Self.displayedOnce = true
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                canStartRide = appState.canStartRide
            }
        }
        .onDisappear {
            animateIn = true
        }
    }
}
struct TranslucentGroupBox: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.content
            .background(.regularMaterial)
    }
}
#Preview {
    PieceShelfView()
        .glassBackgroundEffect()
        .environment(AppState())
}
