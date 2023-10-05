/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view used by the app's buttons.
*/
import OSLog
import SwiftUI

/// A simple button with an image. This is used in the piece shelf.
public struct ImageButton: View {
    var title: String
    var imageName: String
    var imageBundle: Bundle? = nil
    var buttonAction: (ImageButton) -> Void
    // Use this to pass information to the button's action closure.
    var context = [String: Any]()
    
    @Environment(\.isEnabled) var isEnabled
    
    public var body: some View {
        Button {
            buttonAction(self)
        } label: {
            VStack {
                Image(imageName, bundle: imageBundle)
                    .resizable()
                    .scaledToFit()
                    .opacity(isEnabled ? 1.0 : 0.5)
                    
                Text(title)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .padding(.bottom, 10)
            }
        }
        .buttonStyle(.borderless)
        .buttonBorderShape(.roundedRectangle)
    }
}
#Preview {
    ImageButton(title: "Simple Ramp", imageName: "slide_01_metal") { button in
        os_log("Pressed")
    }
    .glassBackgroundEffect(in: .rect(cornerRadius: 14))
    .frame(width: 86, height: 86)
}
