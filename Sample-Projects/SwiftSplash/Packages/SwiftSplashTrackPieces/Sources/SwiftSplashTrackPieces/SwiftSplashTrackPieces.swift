/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Constants and enums the app uses to interact with the Reality Compoer Pro project.
*/

import Foundation

public let bundle = Bundle.module
public let startPieceName = "start"
public let endPieceName = "end"
public let slideTopName = "top"
public let poweredMaterialParameterName = "powered"
public let inConnectionName = "connect_in"
public let inConnectionVectorName = "in_connection_vector"
public let outConnectionName = "connect_out"
public let outConnectionVectorName = "out_connection_vector"
public let placePieceMarkerName = "solidSpheres"
public let shelfPositionLocationName = "shelf_position"
public let uiPositionMarker = "ui_anchor"
public let instructionsMarkerName = "instructions_anchor"
public let selectedGlowName = "glow"
public let startGlowName = "start_glow"
public let materialParameterName = "material"
public let speedMultiplierParameterName = "speed_multiplier"
public let rideRunningParameterName = "ride_running"
public let fillLevelParameterName = "fill_level"
public let startPieceSceneName = "StartPiece.usda"
public let endPieceSceneName = "EndPiece.usda"
public let placePieceMarkerSceneName = "solidSpheres.usda"
public let sortOrderGlassGlobeName = "start_glass"
public let sortOrderWaterName = "waterDrain_ride_animation"
public let fishGlassIdleAnimModelName = "adventureFish_start_glass_idle_animation"
public let fishGlassRideAnimModelName = "adventureFish_start_glass_ride_animation"
public let fishIdleAnimModelName = "adventureFish_start_noGlass_idle_animation"
public let fishRideAnimModelName = "adventureFish_start_noGlass_ride_animation"
public let sortOrderFishGlassSuffix = "noGlass_ride_animation"
public let sortOrderFishSuffix = "glass_ride_animation"
public let sortOrderWaterSuffix = "_water"
public let sortOrderTrackTopsuffix = "_top"
public let sortOrderTrackGlowSuffix = "_top_glow"
public let sortOrderEndWaterName = "end_water"
public let sortOrderEndSlideName = "slide_end_water"
public let sortOrderEndSlideTopName = "slideEnd_top"
public let waterLevelParameterName = "water_level"
public let endParticlesName = "EndParticles"
public let waterFallParticlesName = "waterFallSplash"
public let fireworksParticlesName = "fireWorks"

public enum MaterialType: Int {
    case metal = 0
    case plastic
    case wood

    public var name: String {
        switch self {
            case .metal:
                return "metal"
            case .plastic:
                return "plastic"
            case .wood:
                return "wood"

        }
    }
}
