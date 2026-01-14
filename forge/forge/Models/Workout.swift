//
//  Workout.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import Foundation
import SwiftData

@Model
class Workout {
    var id: UUID
    var name: String?
    var startTime: Date
    var endTime: Date?
    var notes: String?
    var templateId: UUID?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var exercises: [WorkoutExercise]

    init(
        id: UUID = UUID(),
        name: String? = nil,
        startTime: Date = Date(),
        endTime: Date? = nil,
        notes: String? = nil,
        templateId: UUID? = nil,
        exercises: [WorkoutExercise] = []
    ) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
        self.templateId = templateId
        self.exercises = exercises
    }

    var duration: TimeInterval? {
        guard let endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    var isInProgress: Bool {
        endTime == nil
    }

    var totalVolume: Double {
        exercises.reduce(0) { $0 + $1.totalVolume }
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.completedSets.count }
    }

    var personalRecordsCount: Int {
        exercises.reduce(0) { total, workoutExercise in
            total + workoutExercise.sets.filter { $0.isPersonalRecord }.count
        }
    }

    var displayName: String {
        if let name = name, !name.isEmpty {
            return name
        }

        // Auto-generate name from exercises
        let exerciseNames = exercises.compactMap { $0.exercise?.name }
        if exerciseNames.isEmpty {
            return "Workout"
        } else if exerciseNames.count <= 2 {
            return exerciseNames.joined(separator: " & ")
        } else {
            return exerciseNames.prefix(2).joined(separator: ", ") + "..."
        }
    }
}
