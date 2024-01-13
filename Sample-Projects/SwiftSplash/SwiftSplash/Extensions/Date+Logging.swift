/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that formats dates for logging.
*/
import Foundation

extension Date {
    static public var timestamp: String {
        let dateFMT = DateFormatter()
        dateFMT.locale = Locale(identifier: "en_US_POSIX")
        dateFMT.dateFormat = "yyyyMMdd'T'HHmmss.SSSS"
        let now = Date()
        
        return String(format: "%@", dateFMT.string(from: now))
    }
}
