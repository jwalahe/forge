//
//  LiveActivityManager.swift
//  forge
//
//  Created by Jwala Kompalli on 2/5/26.
//

import ActivityKit
import Foundation

@MainActor
class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<ForgeRestTimerAttributes>?

    private init() {}

    // MARK: - Start

    func startRestTimerActivity(
        exerciseName: String,
        setInfo: String,
        totalDuration: Int
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // End any existing activity first
        endRestTimerActivity()

        let attributes = ForgeRestTimerAttributes(
            exerciseName: exerciseName,
            setInfo: setInfo,
            totalDuration: totalDuration
        )

        let initialState = ForgeRestTimerAttributes.ContentState(
            remainingSeconds: totalDuration,
            isPaused: false
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
        } catch {
            print("[LiveActivity] Failed to start: \(error.localizedDescription)")
        }
    }

    // MARK: - Update

    func updateRestTimer(remainingSeconds: Int, isPaused: Bool) {
        guard let activity = currentActivity else { return }

        let updatedState = ForgeRestTimerAttributes.ContentState(
            remainingSeconds: remainingSeconds,
            isPaused: isPaused
        )

        Task {
            await activity.update(
                ActivityContent(state: updatedState, staleDate: nil)
            )
        }
    }

    // MARK: - End

    func endRestTimerActivity() {
        guard let activity = currentActivity else { return }

        let finalState = ForgeRestTimerAttributes.ContentState(
            remainingSeconds: 0,
            isPaused: false
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }

        currentActivity = nil
    }
}
