/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension on Float containing an app-specific nearly equal to operator.
*/

import Foundation

infix operator ==~

public extension Float {
    
    /// Float comparison with an epislon of 0.00001. This isn't a general purpose nearly-equal-to operator;
    /// it uses an epsilon value tuned to work well for snapping track pieces together.
    static func ==~ (lhs: Float, rhs: Float) -> Bool {
        return abs(lhs - rhs) <= 1e-5
    }
}
