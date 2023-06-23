/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Marks an entity as only being relevant to a specific map location.
*/

import RealityKit

/// A component that specifies which region an entity should be shown for. Make sure  you register
/// this component in your app delegate using `RegionSpecificComponent.registerComponent()`
public struct RegionSpecificComponent: Component, Codable {
    public var region: Region = .yosemite

    public init() {
    }
    
    public init(region: Region) {
        self.region = region
    }
}

