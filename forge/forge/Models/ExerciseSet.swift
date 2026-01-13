//
//  ExerciseSet.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import Foundation
import SwiftData

@Model
class ExerciseSet {
    var id: UUID
    var workoutExercise: WorkoutExercise?
    var setNumber: Int
    var weight: Double?
    var reps: Int?
    var setType: SetType
    var completedAt: Date?
    var isPersonalRecord: Bool

    init(
        id: UUID = UUID(),
        workoutExercise: WorkoutExercise? = nil,
        setNumber: Int,
        weight: Double? = nil,
        reps: Int? = nil,
        setType: SetType = .working,
        completedAt: Date? = nil,
        isPersonalRecord: Bool = false
    ) {
        self.id = id
        self.workoutExercise = workoutExercise
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.setType = setType
        self.completedAt = completedAt
        self.isPersonalRecord = isPersonalRecord
    }

    var isCompleted: Bool {
        completedAt != nil && weight != nil && reps != nil
    }

    var volume: Double {
        guard let weight = weight, let reps = reps else { return 0 }
        return weight * Double(reps)
    }
}

// MARK: - SetType Enum

extension ExerciseSet {
    enum SetType: String, Codable, CaseIterable {
        case warmup
        case working
        case dropSet
        case toFailure

        var displayName: String {
            switch self {
            case .warmup: return "Warmup"
            case .working: return "Working"
            case .dropSet: return "Drop Set"
            case .toFailure: return "To Failure"
            }
        }
    }
}
