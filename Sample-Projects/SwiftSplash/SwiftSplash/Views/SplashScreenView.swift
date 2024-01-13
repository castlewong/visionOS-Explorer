/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view holding the app's splash screen.
*/
import RealityKit
import SwiftUI
struct SplashScreenView: View {
    @Environment(AppState.self) var appState
    
    var body: some View {
        VStack {
            Text("Swift Splash")
                .font(.extraLargeTitle2)
                .fontWeight(.bold)
            Text("Build an epic water ride this adventurous fish won’t forget.")
                .frame(width: 300)
                .font(.system(size: 18))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top, -5)
                .padding(.bottom, 10)
                
            if appState.phase == .loadingAssets {
                ProgressView("Loading Assets…")
            } else {
                Button("Start Building") {
                    appState.startBuilding()
                }
            }
        }
        .offset(y: 100)
        .frame(maxWidth: 600, maxHeight: 440, alignment: .center)
        .background {
            Image("swiftSplashHero")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .offset(y: -110)
        }
        .onAppear {
            // Play menu music as content loads.
            appState.music = .menu
        }
    }
}
#Preview {
    SplashScreenView()
        .glassBackgroundEffect()
        .environment(AppState())
}
