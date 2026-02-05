//
//  ForgeRestTimerLiveActivity.swift
//  ForgeWidgetExtension
//
//  Created by Jwala Kompalli on 2/5/26.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct ForgeRestTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ForgeRestTimerAttributes.self) { context in
            // Lock screen / banner view
            lockScreenView(context: context)
                .activityBackgroundTint(.black.opacity(0.8))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded region
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.exerciseName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(1)

                        Text(context.attributes.setInfo)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerText(context.state.remainingSeconds))
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundStyle(timerColor(context.state.remainingSeconds))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: clampedProgress(context: context))
                        .tint(timerColor(context.state.remainingSeconds))
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(.cyan)
                    .font(.caption)
            } compactTrailing: {
                Text(timerText(context.state.remainingSeconds))
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(.cyan)
            } minimal: {
                Text(minimalText(context.state.remainingSeconds))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.cyan)
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<ForgeRestTimerAttributes>) -> some View {
        HStack(spacing: 16) {
            // Timer circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: clampedProgress(context: context))
                    .stroke(timerColor(context.state.remainingSeconds), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                Image(systemName: context.state.isPaused ? "pause.fill" : "timer")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(timerColor(context.state.remainingSeconds))
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.exerciseName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)

                Text(context.attributes.setInfo)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Countdown
            VStack(alignment: .trailing, spacing: 2) {
                Text(timerText(context.state.remainingSeconds))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(timerColor(context.state.remainingSeconds))

                Text(context.state.isPaused ? "Paused" : "Rest")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
    }

    // MARK: - Helpers

    private func clampedProgress(context: ActivityViewContext<ForgeRestTimerAttributes>) -> Double {
        let total = context.attributes.totalDuration
        guard total > 0 else { return 0 }
        let remaining = context.state.remainingSeconds
        return min(max(Double(remaining) / Double(total), 0), 1)
    }

    private func timerText(_ seconds: Int) -> String {
        let mins = max(seconds, 0) / 60
        let secs = max(seconds, 0) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func minimalText(_ seconds: Int) -> String {
        let s = max(seconds, 0)
        if s >= 60 {
            return "\(s / 60)m"
        }
        return "\(s)s"
    }

    private func timerColor(_ remainingSeconds: Int) -> Color {
        if remainingSeconds <= 10 {
            return .red
        } else if remainingSeconds <= 30 {
            return .orange
        }
        return .cyan
    }
}
