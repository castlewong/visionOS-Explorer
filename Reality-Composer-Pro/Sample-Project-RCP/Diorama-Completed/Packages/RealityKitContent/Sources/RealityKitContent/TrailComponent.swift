/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that marks an entity as being an animated trail on the diorama map.
*/

import RealityKit

// Ensure you register this component in your app’s delegate using:
// TrailComponent.registerComponent()
/// A component that marks an entity as a trail. Make sure  you register this component in your app
/// delegate using `RegionSpecificComponent.registerComponent()`
public struct TrailComponent: Component, Codable {
    
    public init() {
    }
}

