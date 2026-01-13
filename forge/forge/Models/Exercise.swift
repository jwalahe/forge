//
//  Exercise.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import Foundation
import SwiftData

@Model
class Exercise {
    var id: UUID
    var name: String
    var muscleGroup: MuscleGroup
    var equipment: Equipment
    var isCustom: Bool
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: MuscleGroup,
        equipment: Equipment,
        isCustom: Bool = false,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.isCustom = isCustom
        self.isArchived = isArchived
    }
}

// MARK: - Enums

extension Exercise {
    enum MuscleGroup: String, Codable, CaseIterable {
        case chest
        case back
        case shoulders
        case biceps
        case triceps
        case quads
        case hamstrings
        case glutes
        case calves
        case core
        case fullBody

        var displayName: String {
            switch self {
            case .chest: return "Chest"
            case .back: return "Back"
            case .shoulders: return "Shoulders"
            case .biceps: return "Biceps"
            case .triceps: return "Triceps"
            case .quads: return "Legs (Quads)"
            case .hamstrings: return "Legs (Hamstrings)"
            case .glutes: return "Legs (Glutes)"
            case .calves: return "Calves"
            case .core: return "Core"
            case .fullBody: return "Full Body"
            }
        }
    }

    enum Equipment: String, Codable, CaseIterable {
        case barbell
        case dumbbell
        case cable
        case machine
        case bodyweight
        case other

        var displayName: String {
            switch self {
            case .barbell: return "Barbell"
            case .dumbbell: return "Dumbbell"
            case .cable: return "Cable"
            case .machine: return "Machine"
            case .bodyweight: return "Bodyweight"
            case .other: return "Other"
            }
        }
    }
}
