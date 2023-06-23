/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A gradient view.
*/

import SwiftUI

/// A view that displays a vertical gradient.
struct GradientView: View {
    
    /// A fill style for the gradient.
    let style: any ShapeStyle
    
    /// The height of the view in points.
    let height: Double
    
    /// The start point of the gradient.
    ///
    /// This value can be `.top` or .`bottom`.
    let startPoint: UnitPoint
    
    /// Creates a gradient view.
    /// - Parameters:
    ///   - style: A fill style for the gradient.
    ///   - height: The height of the view in points.
    ///   - startPoint: The start point of the gradient. The system throws an fatal error if that value
    ///   isn't `.top` or `.bottom`.
    init(style: any ShapeStyle, height: Double, startPoint: UnitPoint) {
        guard startPoint == .top || startPoint == .bottom else { fatalError() }
        self.style = style
        self.height = height
        self.startPoint = startPoint
    }
    
    var body: some View {
        Rectangle()
            .fill(AnyShapeStyle(style))
            .frame(height: height)
            .mask {
                LinearGradient(colors: [.clear, .black, .black],
                               startPoint: startPoint,
                               // Set the end point to be the opposite of the start.
                               endPoint: startPoint == .top ? .bottom : .top)
            }
    }
}

#Preview {
    GradientView(style: .thinMaterial, height: 200, startPoint: .top)
}
