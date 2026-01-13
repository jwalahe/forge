//
//  WorkoutExercise.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import Foundation
import SwiftData

@Model
class WorkoutExercise {
    var id: UUID
    var workout: Workout?
    var exercise: Exercise?
    var order: Int
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.workoutExercise)
    var sets: [ExerciseSet]

    init(
        id: UUID = UUID(),
        workout: Workout? = nil,
        exercise: Exercise? = nil,
        order: Int,
        notes: String? = nil,
        sets: [ExerciseSet] = []
    ) {
        self.id = id
        self.workout = workout
        self.exercise = exercise
        self.order = order
        self.notes = notes
        self.sets = sets
    }

    var completedSets: [ExerciseSet] {
        sets.filter { $0.isCompleted }
    }

    var totalVolume: Double {
        completedSets.reduce(0) { $0 + $1.volume }
    }
}
