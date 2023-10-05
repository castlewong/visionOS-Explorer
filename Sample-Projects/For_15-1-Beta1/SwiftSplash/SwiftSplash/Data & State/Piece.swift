/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that holds information about one slide piece.
*/

import Foundation
import Combine
import SwiftSplashTrackPieces
import UIKit
import RealityKit
/// Represents a single connectable track piece, including elements used in UI, such as name and image.
public struct Piece: Identifiable {
    
    /// The name of the piece to display in UI.
    public var name: String
    
    /// The corresponding key to store this piece in dictionaries.
    public var key: TilePieceKey
    
    /// The scene in the Reality Composer Pro project that contains the piece.
    public var sceneName: String
    
    init(name: String, key: TilePieceKey,
         sceneName: String) {
        self.name = name
        self.key = key
        self.id = UUID()
        self.sceneName = sceneName
    }
    
    /// Calcualate ID based on name, which must be unique.
    public var id: UUID
}

/// Implements `Codable` for `Piece`. Because the sample has derived keys, this object can't use auto encoding.
extension Piece: Codable {
    
    enum CodingKeys: String, CodingKey {
        case name
        case key
        case imageFilename
        case sceneName
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(key.rawValue, forKey: .key)
        try container.encode(sceneName, forKey: .sceneName)
    }
    
    public enum PieceError: Error {
        case unableToDecodeKeyError
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(type(of: name), forKey: .name)
        let keyString = try container.decode(String.self, forKey: .key)
        let sceneName = try container.decode(String.self, forKey: .sceneName)
        guard let key = TilePieceKey(rawValue: keyString) else { throw PieceError.unableToDecodeKeyError }
        
        self.init(name: name, key: key, sceneName: sceneName)
    }
}

