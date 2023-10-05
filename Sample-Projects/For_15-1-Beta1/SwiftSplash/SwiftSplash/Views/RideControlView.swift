/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view for controlling the ride while it's running.
*/

import SwiftUI
struct RideControlView: View {
    @Environment(AppState.self) var appState
    @State var elapsed: Double = 0.0
    @State private var animateIn = true
    @State private var canStartRide = false
    
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            Button {
                shouldPauseRide.toggle()
                
                if !shouldPauseRide {
                    appState.rideStartTime += Date.timeIntervalSinceReferenceDate - pauseStartTime
                    SoundEffect.enqueueEffectsForRide(appState, resume: true)
                } else {
                    SoundEffect.stopLoops()
                }
                
                appState.music = shouldPauseRide ? .silent : .ride
            } label: {
                if shouldPauseRide {
                    Label("Play", systemImage: "play.fill")
                        .labelStyle(.iconOnly)
                } else {
                    Label("Pause", systemImage: "pause.fill")
                        .labelStyle(.iconOnly)
                }
            }
            .buttonStyle(.borderless)
            .padding(.leading, 17)
            let elapsedTime = min(max(elapsed, 0), appState.rideDuration)
            ProgressView(value: elapsedTime, total: appState.rideDuration)
                .tint(.white)
                .onReceive(timer) { _ in
                    if pauseStartTime == 0 {
                        elapsed = (Date.timeIntervalSinceReferenceDate - appState.rideStartTime)
                    } else {
                        elapsed = (Date.timeIntervalSinceReferenceDate - appState.rideStartTime -
                                   (Date.timeIntervalSinceReferenceDate - pauseStartTime))
                    }
                }
            
            Button {
                shouldCancelRide = true
                Task {
                    // Pause a moment to let the previous ride cancel.
                    try await Task.sleep(for: .seconds(0.1))
                    SoundEffect.stopLoops()
                    appState.resetRideAnimations()
                    appState.goalPiece?.stopWaterfall()
                    appState.startRide()
                    appState.music = .ride
                }
            } label: {
                Label("Restart Ride", systemImage: "arrow.counterclockwise")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .padding(.trailing, 9)
        }
        .opacity(animateIn ? 0.0 : 1.0)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                withAnimation(.easeInOut(duration: 0.7)) {
                    animateIn = false
                }
            }
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                canStartRide = appState.canStartRide
            }
        }
        .onDisappear {
            animateIn = true
        }
    }
}
struct RideControlView_Previews: PreviewProvider {
    static var previews: some View {
        RideControlView()
            .environment(AppState())
    }
}
