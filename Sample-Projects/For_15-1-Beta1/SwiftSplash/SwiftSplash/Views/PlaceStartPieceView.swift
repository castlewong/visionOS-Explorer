/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that instructs the player to place the first piece of the ride.
*/

import SwiftUI
struct PlaceStartPieceView: View {
    @Environment(AppState.self) var appState
    let isAttachment: Bool
    
    init(asAttachment: Bool = true) {
        isAttachment = asAttachment
    }
    
    var body: some View {
        Text("Pinch and drag to place the first piece of the ride in your room.")
            .font(.system(size: 18))
            .fontWeight(.bold)
            .frame(width: 345)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            
            .frame(maxWidth: 405, maxHeight: 100, alignment: .center)
            .glassBackgroundEffect()
            .onTapGesture {
                SoundEffect.fishGasp.play(on: appState.startPiece ?? appState.root)
            }
    }
}
#Preview {
    PlaceStartPieceView()
        .glassBackgroundEffect()
        .environment(AppState())
}
