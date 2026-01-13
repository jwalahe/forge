//
//  Constants.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI

enum AppConstants {
    // MARK: - UI Constants
    static let primaryButtonHeight: CGFloat = 56
    static let secondaryButtonHeight: CGFloat = 44
    static let cornerRadius: CGFloat = 12
    static let minTouchTarget: CGFloat = 44

    // MARK: - Workout Constants
    static let defaultRestTimerSeconds: Int = 90
    static let maxSetsPerExercise: Int = 20

    // MARK: - Animation Constants
    static let standardAnimationDuration: Double = 0.3
    static let quickAnimationDuration: Double = 0.15

    // MARK: - Haptics
    enum Haptic {
        static let light = UIImpactFeedbackGenerator(style: .light)
        static let medium = UIImpactFeedbackGenerator(style: .medium)
        static let heavy = UIImpactFeedbackGenerator(style: .heavy)
        static let success = UINotificationFeedbackGenerator()
    }
}

// MARK: - Color Extensions

extension Color {
    static let forgeAccent = Color.accentColor
    static let forgeSuccess = Color.green
    static let forgeWarning = Color.red
    static let forgeMuted = Color.secondary
}

// MARK: - App Settings Keys

enum SettingsKey: String {
    case weightUnit = "weight_unit"
    case defaultRestTimer = "default_rest_timer"
    case appearanceMode = "appearance_mode"
}

enum WeightUnit: String, Codable, CaseIterable {
    case lbs
    case kg

    var displayName: String {
        switch self {
        case .lbs: return "lbs"
        case .kg: return "kg"
        }
    }
}
