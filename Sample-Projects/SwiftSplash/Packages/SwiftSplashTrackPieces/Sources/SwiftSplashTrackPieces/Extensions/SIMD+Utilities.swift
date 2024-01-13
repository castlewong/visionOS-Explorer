/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Contains extensions on SIMD objects.
*/

import Foundation
import RealityKit
import simd

public let pi_2 = Float.pi / 2.0

/// Adds an approximately equal operator, a convenience `up` vector, and some utility methods.
public extension SIMD3 where Scalar == Float {
    
    /// Returns a vector that represents an up vector. Used for rotating around the `Y` axis (yaw)
    static let up = SIMD3<Float>(x: 0, y: 1, z: 0)
    
    /// The magnitude of this vector.
    var magnitude: Float {
        return simd_length(self)
    }
    
    /// Returns a vector with all values set to `0.0`.
    static let zero = SIMD3<Float>.zero
}

public extension simd_float4x4 {
    
    /// Returns the forward vector for the orientation represented by this matrix.
    var forward: SIMD3<Float> {
        simd_normalize(SIMD3<Float>(columns.2.x, columns.2.y, columns.2.z))
    }
}
