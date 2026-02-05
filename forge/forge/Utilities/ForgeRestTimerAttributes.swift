//
//  ForgeRestTimerAttributes.swift
//  forge
//
//  Created by Jwala Kompalli on 2/5/26.
//

import ActivityKit
import Foundation

struct ForgeRestTimerAttributes: ActivityAttributes {
    /// Fixed context that doesn't change during the Live Activity
    var exerciseName: String
    var setInfo: String
    var totalDuration: Int

    /// Dynamic state that updates as the timer ticks
    struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
        var isPaused: Bool
    }
}
