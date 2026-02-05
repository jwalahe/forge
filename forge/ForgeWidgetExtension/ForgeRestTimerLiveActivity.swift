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
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded region
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeading(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailing(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottom(context: context)
                }
            } compactLeading: {
                // Compact leading — timer icon
                Image(systemName: "timer")
                    .foregroundColor(.cyan)
                    .font(.caption)
            } compactTrailing: {
                // Compact trailing — countdown
                Text(timerText(context.state.remainingSeconds))
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.cyan)
            } minimal: {
                // Minimal — just the time
                Text(minimalText(context.state.remainingSeconds))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.cyan)
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
                    .trim(from: 0, to: progress(context: context))
                    .stroke(timerColor(context.state.remainingSeconds), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                Image(systemName: context.state.isPaused ? "pause.fill" : "timer")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(timerColor(context.state.remainingSeconds))
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.exerciseName)
                    .font(.system(.headline))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(context.attributes.setInfo)
                    .font(.system(.subheadline))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Countdown
            VStack(alignment: .trailing, spacing: 2) {
                Text(timerText(context.state.remainingSeconds))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(timerColor(context.state.remainingSeconds))

                Text(context.state.isPaused ? "Paused" : "Rest")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
    }

    // MARK: - Dynamic Island Expanded Views

    @ViewBuilder
    private func expandedLeading(context: ActivityViewContext<ForgeRestTimerAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(context.attributes.exerciseName)
                .font(.system(.headline))
                .fontWeight(.bold)
                .lineLimit(1)

            Text(context.attributes.setInfo)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func expandedTrailing(context: ActivityViewContext<ForgeRestTimerAttributes>) -> some View {
        Text(timerText(context.state.remainingSeconds))
            .font(.system(size: 24, weight: .bold, design: .monospaced))
            .foregroundColor(timerColor(context.state.remainingSeconds))
    }

    @ViewBuilder
    private func expandedBottom(context: ActivityViewContext<ForgeRestTimerAttributes>) -> some View {
        // Progress bar
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 6)

                Capsule()
                    .fill(timerColor(context.state.remainingSeconds))
                    .frame(width: geometry.size.width * progress(context: context), height: 6)
            }
        }
        .frame(height: 6)
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func progress(context: ActivityViewContext<ForgeRestTimerAttributes>) -> CGFloat {
        let total = context.attributes.totalDuration
        guard total > 0 else { return 0 }
        let remaining = context.state.remainingSeconds
        return CGFloat(remaining) / CGFloat(total)
    }

    private func timerText(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func minimalText(_ seconds: Int) -> String {
        if seconds >= 60 {
            return "\(seconds / 60)m"
        }
        return "\(seconds)s"
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
