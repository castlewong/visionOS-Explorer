/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that marks an entity as part of a flock.
*/

import RealityKit

public struct FlockingComponent: Component, Codable {
    public var velocity = SIMD3<Float>(repeating: 0.0)
    public var seekPosition = SIMD3<Float>(0.0, 1.5, 0.0)
    
    public init() { }
}
