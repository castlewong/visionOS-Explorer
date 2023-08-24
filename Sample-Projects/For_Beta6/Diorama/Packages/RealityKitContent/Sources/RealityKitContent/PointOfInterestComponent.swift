/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that marks an entity as a point of interest on the diorama map.
*/
import RealityKit
import SwiftUI

public enum Region: String, Codable, CaseIterable {
    case yosemite
    case catalina
    
    public func opacity(forSliderValue sliderValue: Float) -> Float {
        switch self {
        case .yosemite: return 1.0 - sliderValue
        case .catalina: return sliderValue
        }
    }
    
    public func gain(forSliderValue sliderValue: Float) -> Audio.Decibel {
        let fullyOn: Audio.Decibel = 0
        let fullyOff: Audio.Decibel = -100
        
        switch self {
        case .yosemite: return Audio.Decibel.lerp(a: fullyOn, b: fullyOff, t: Audio.Decibel(sliderValue))
        case .catalina: return Audio.Decibel.lerp(a: fullyOff, b: fullyOn, t: Audio.Decibel(sliderValue))
        }
    }
}

public extension FloatingPoint {
    static func lerp(a: Self, b: Self, t: Self) -> Self {
        let one = Self(1)
        let oneMinusT = one - t
        let aTimesOneMinusT = a * oneMinusT
        let bTimesT = b * t
        return aTimesOneMinusT + bTimesT
    }
}

public struct PointOfInterestComponent: Component, Codable {

    public var region: Region = .yosemite

    public var name: String = "Learn More"
    
    public var description: String? = nil
    
    public var mainImageName: String? = nil
    public var secondImageName: String? = nil
    public var thirdImageName: String? = nil
    
    public var imageNames: [String] {
        [mainImageName, secondImageName, thirdImageName].compactMap({ $0 })
    }

    public init() {}
}
