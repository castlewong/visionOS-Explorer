/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Hand tracking updates.
*/

#if targetEnvironment(simulator)
import ARKit
#else
@preconcurrency import ARKit
#endif
import SwiftUI

/// A model that contains up-to-date hand coordinate information.
@MainActor
class HeartGestureModel: ObservableObject, @unchecked Sendable {
    let session = ARKitSession()
    var handTracking = HandTrackingProvider()
    @Published var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
    
    struct HandsUpdates {
        var left: HandAnchor?
        var right: HandAnchor?
    }
    
    func start() async {
        do {
            if HandTrackingProvider.isSupported {
                print("ARKitSession starting.")
                try await session.run([handTracking])
            }
        } catch {
            print("ARKitSession error:", error)
        }
    }
    
    func publishHandTrackingUpdates() async {
        for await update in handTracking.anchorUpdates {
            switch update.event {
            case .updated:
                let anchor = update.anchor
                
                // Publish updates only if the hand and the relevant joints are tracked.
                guard anchor.isTracked else { continue }
                
                // Update left hand info.
                if anchor.chirality == .left {
                    latestHandTracking.left = anchor
                } else if anchor.chirality == .right { // Update right hand info.
                    latestHandTracking.right = anchor
                }
            default:
                break
            }
        }
    }
    
    func monitorSessionEvents() async {
        for await event in session.events {
            switch event {
            case .authorizationChanged(let type, let status):
                if type == .handTracking && status != .allowed {
                    // Stop the game, ask the user to grant hand tracking authorization again in Settings.
                }
            @unknown default:
                print("Session event \(event)")
            }
        }
    }
  
    /// Computes a transform representing the heart gesture performed by the user.
    ///
    /// - Returns:
    ///  * A right-handed transform for the heart gesture, where:
    ///     * The origin is in the center of the gesture
    ///     * The X axis is parallel to the vector from left thumb knuckle to right thumb knuckle
    ///     * The Y axis is parallel to the vector from right thumb tip to right index finger tip.
    ///  * `nil` if either of the hands isn't tracked or the user isn't performing a heart gesture
    ///  (the index fingers and thumbs of both hands need to touch).
    func computeTransformOfUserPerformedHeartGesture() -> simd_float4x4? {
        // Get the latest hand anchors, return false if either of them isn't tracked.
        guard let leftHandAnchor = latestHandTracking.left,
              let rightHandAnchor = latestHandTracking.right,
              leftHandAnchor.isTracked, rightHandAnchor.isTracked else {
            return nil
        }
        
        // Get all required joints and check if they are tracked.
        let leftHandThumbKnuckle = leftHandAnchor.skeleton.joint(named: .handThumbKnuckle)
        let leftHandThumbTipPosition = leftHandAnchor.skeleton.joint(named: .handThumbTip)
        let leftHandIndexFingerTip = leftHandAnchor.skeleton.joint(named: .handIndexFingerTip)
        let rightHandThumbKnuckle = rightHandAnchor.skeleton.joint(named: .handThumbKnuckle)
        let rightHandThumbTipPosition = rightHandAnchor.skeleton.joint(named: .handThumbTip)
        let rightHandIndexFingerTip = rightHandAnchor.skeleton.joint(named: .handIndexFingerTip)
        
        guard leftHandIndexFingerTip.isTracked && leftHandThumbTipPosition.isTracked &&
                rightHandIndexFingerTip.isTracked && rightHandThumbTipPosition.isTracked &&
                leftHandThumbKnuckle.isTracked && rightHandThumbKnuckle.isTracked else {
            return nil
        }
        
        // Get the position of all joints in world coordinates.
        let leftHandThumbKnuckleWorldPosition = matrix_multiply(leftHandAnchor.transform, leftHandThumbKnuckle.rootTransform).columns.3.xyz
        let leftHandThumbTipWorldPosition = matrix_multiply(leftHandAnchor.transform, leftHandThumbTipPosition.rootTransform).columns.3.xyz
        let leftHandIndexFingerTipWorldPosition = matrix_multiply(leftHandAnchor.transform, leftHandIndexFingerTip.rootTransform).columns.3.xyz
        let rightHandThumbKnuckleWorldPosition = matrix_multiply(rightHandAnchor.transform, rightHandThumbKnuckle.rootTransform).columns.3.xyz
        let rightHandThumbTipWorldPosition = matrix_multiply(rightHandAnchor.transform, rightHandThumbTipPosition.rootTransform).columns.3.xyz
        let rightHandIndexFingerTipWorldPosition = matrix_multiply(rightHandAnchor.transform, rightHandIndexFingerTip.rootTransform).columns.3.xyz
        
        let indexFingersDistance = distance(leftHandIndexFingerTipWorldPosition, rightHandIndexFingerTipWorldPosition)
        let thumbsDistance = distance(leftHandThumbTipWorldPosition, rightHandThumbTipWorldPosition)
        
        // Heart gesture detection is true when the distance between the index finger tips centers
        // and the distance between the thumb tip centers is each less than four centimeters.
        let isHeartShapeGesture = indexFingersDistance < 0.04 && thumbsDistance < 0.04
        if !isHeartShapeGesture {
            return nil
        }
        
        // Compute a position in the middle of the heart gesture.
        let halfway = (rightHandIndexFingerTipWorldPosition - leftHandThumbTipWorldPosition) / 2
        let heartMidpoint = rightHandIndexFingerTipWorldPosition - halfway
        
        // Compute the vector from left thumb knuckle to right thumb knuckle and normalize (X axis).
        let xAxis = normalize(rightHandThumbKnuckleWorldPosition - leftHandThumbKnuckleWorldPosition)
        
        // Compute the vector from right thumb tip to right index finger tip and normalize (Y axis).
        let yAxis = normalize(rightHandIndexFingerTipWorldPosition - rightHandThumbTipWorldPosition)
        
        let zAxis = normalize(cross(xAxis, yAxis))
        
        // Create the final transform for the heart gesture from the three axes and midpoint vector.
        let heartMidpointWorldTransform = simd_matrix(
            SIMD4(xAxis.x, xAxis.y, xAxis.z, 0),
            SIMD4(yAxis.x, yAxis.y, yAxis.z, 0),
            SIMD4(zAxis.x, zAxis.y, zAxis.z, 0),
            SIMD4(heartMidpoint.x, heartMidpoint.y, heartMidpoint.z, 1)
        )
        return heartMidpointWorldTransform
    }
}
