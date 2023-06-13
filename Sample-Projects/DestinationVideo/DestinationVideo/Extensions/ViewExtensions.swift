/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Helper extensions to simplify multiplatform development.
*/

import SwiftUI
import UIKit

extension View {
    
    /// A helper function that returns a platform-specific value.
    func valueFor<V>(iOS: V, tvOS: V, visionOS: V) -> V {
        #if os(xrOS)
        visionOS
        #elseif os(tvOS)
        tvOS
        #else
        iOS
        #endif
    }
    
    /// A Boolean value that indicates whether the current platform is visionOS.
    ///
    /// If the value is `true`, `isMobile` is also true.
    var isVision: Bool {
        #if os(xrOS)
        true
        #else
        false
        #endif
    }
    
    /// A Boolean value that indicates whether the current platform is iOS or iPadOS.
    var isMobile: Bool {
        #if os(iOS)
        true
        #else
        false
        #endif
    }
    
    /// A Boolean value that indicates whether the current platform is tvOS.
    var isTV: Bool {
        #if os(tvOS)
        true
        #else
        false
        #endif
    }
    
    /// A debugging function to add a border around a view.
    func debugBorder(color: Color = .red, width: CGFloat = 1.0, opacity: CGFloat = 1.0) -> some View {
        self
            .border(color, width: width)
            .opacity(opacity)
    }
}
