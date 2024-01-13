/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A collection of view modifiers to facilitate a consistent look and feel in the app.
*/

import SwiftUI

public struct GreenBackground: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(.green.opacity(0.2))
            .glassBackgroundEffect(in: .rect(cornerRadius: 25))
    }
}

public struct TitleStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.system(size: 40, weight: .semibold))
    }
}

public struct DioramaSliderStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .tint(.green)
            .frame(width: 500, height: 20)
            .padding(.all, 20)
    }
}

public extension View {
    func greenBackground() -> some View {
        modifier(GreenBackground())
    }
    
    func titleStyle() -> some View {
        modifier(TitleStyle())
    }
    
    func dioramaSliderStyle() -> some View {
        modifier(DioramaSliderStyle())
    }
}

#Preview {
    Text("Hello")
        .titleStyle()
        .padding()
        .greenBackground()
}
