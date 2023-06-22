/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Assets for the World app.
*/

import Foundation

/// Bundle for the WorldAssets project
public let worldAssetsBundle = Bundle.module
public let sceneName = "Earth.usda"
public let rootNodeName = "Earth"
public let panSpeedParameterName = "pan_speed"
public let minimumCloudOpacityParameterName = "cloud_min_opacity"
public let maximumCloudOpacityParameterName = "cloud_max_opacity"
public let lightsMaximuIntensityParameterName = "light_max_intensity"

/// The name of the material parameter that indicates the sun's angle.
///
/// This is a clamped float where a value of 0.0 (or 1.0) refers to light
/// coming from directly in front of the object and 0.5 refers to light
/// coming from directly behind the model. The model can use this information
/// to adjust any material effects accordingly, like whether the nighttime
/// lights should be visible on the Earth's surface.
public let sunAngleParameterName = "sun_angle"
