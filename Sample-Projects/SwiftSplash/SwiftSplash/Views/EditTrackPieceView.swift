/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view used as an attachment to edit the selected piece or pieces.
*/
import SwiftSplashTrackPieces
import SwiftUI
struct EditTrackPieceView: View {
    @Environment(AppState.self) var appState
    @State private var isSelecting = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Button {
                    appState.selectConnectedPieces()
                } label: {
                    Label("Select Attached", systemImage: "plus.square.dashed")
                    .fontWeight(.semibold)
                    .frame(width: 180)
                }
                .padding(.leading, 20)
                
                Spacer()
                
                Button(role: .destructive) {
                    if let goalPiece = appState.goalPiece {
                        if appState.trackPieceBeingEdited == goalPiece ||
                            appState.additionalSelectedTrackPieces.contains(goalPiece) {
                            goalPiece.removeFromParent()
                        }
                    }
                    appState.deleteSelectedPieces()
                    
                } label: {
                    Label("Delete", systemImage: "trash")
                        .labelStyle(.iconOnly)
                }
                .disabled(appState.trackPieceBeingEdited == appState.startPiece)
                Button {
                    appState.clearSelection(keepPrimary: false)
                } label: {
                    Label("Dismiss", systemImage: "checkmark")
                        .labelStyle(.iconOnly)
                }
                .padding(.trailing, 5)
            }
            .padding(.vertical)
            .frame(width: 350)
            .background(.regularMaterial)
            
            HStack {
                Button {
                    appState.setMaterialForAllSelected(.metal)
                } label: {
                    VStack {
                        Image(decorative: "metalPreview")
                            .resizable()
                            .frame(width: 50, height: 50)
                        Text("Metal")
                    }
                    .padding(.vertical, 10)
                }
                
                Button {
                    appState.setMaterialForAllSelected(.wood)
                } label: {
                    VStack {
                        Image(decorative: "woodPreview")
                            .resizable()
                            .frame(width: 50, height: 50)
                        Text("Wood")
                    }
                    .padding(.vertical, 10)
                }
                Button {
                    appState.setMaterialForAllSelected(.plastic)
                } label: {
                    VStack {
                        Image(decorative: "plasticPreview")
                            .resizable()
                            .frame(width: 50, height: 50)
                        Text("Plastic")
                    }
                    .padding(.vertical, 10)
                }
            }
            .buttonBorderShape(.roundedRectangle(radius: 15))
            .buttonStyle(.borderless)
            .padding()
        }
        .glassBackgroundEffect()
    }
}
#Preview {
    VStack {
        Spacer()
        EditTrackPieceView()
            .environment(AppState())
    }
}
