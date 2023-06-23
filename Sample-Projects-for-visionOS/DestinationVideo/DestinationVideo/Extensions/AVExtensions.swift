/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that represents the result of an audio session interruption, such as a phone call.
*/

import AVFoundation

// A simple type that unpacks the relevant values from an AVAudioSession interruption event.
struct InterruptionResult {
    
    let type: AVAudioSession.InterruptionType
    let options: AVAudioSession.InterruptionOptions
    
    init?(_ notification: Notification) {
        // Determine the interruption type and options.
        guard let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? AVAudioSession.InterruptionType,
              let options = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? AVAudioSession.InterruptionOptions else {
            return nil
        }
        self.type = type
        self.options = options
    }
}
