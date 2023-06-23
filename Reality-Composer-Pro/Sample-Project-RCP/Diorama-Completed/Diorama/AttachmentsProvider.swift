/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that maintains references to its attachment views.
*/

import SwiftUI
import Observation

@Observable
final class AttachmentsProvider {

    var attachments: [ObjectIdentifier: AnyView] = [:]

    var sortedTagViewPairs: [(tag: ObjectIdentifier, view: AnyView)] {
        attachments.map { key, value in
            (tag: key, view: value)
        }.sorted { $0.tag < $1.tag }
    }
}
