/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Constants that define named destinations the app supports.
*/

import Foundation

enum Destination: String, CaseIterable, Identifiable, Codable {
    
    case beach
    case camping
    case creek
    case hillside
    case lake
    case ocean
    case park
    
    var id: Self { self }
    
    /// The environment image to load.
    var imageName: String { "\(rawValue)_scene" }
    
    /// A number of degrees to rotate the 360 "destination" image to provide the best initial view.
    var rotationDegrees: Double {
        switch self {
        case .beach: 55
        case .camping: -55
        case .creek: 0
        case .hillside: 0
        case .lake: -55
        case .ocean: 0
        case .park: 190
        }
    }
}
