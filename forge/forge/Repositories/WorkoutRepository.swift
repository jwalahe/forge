//
//  WorkoutRepository.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import Foundation
import SwiftData

@MainActor
class WorkoutRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func createWorkout(name: String? = nil, templateId: UUID? = nil) -> Workout {
        let workout = Workout(name: name, templateId: templateId)
        modelContext.insert(workout)
        return workout
    }

    // MARK: - Read

    func fetchAllWorkouts() -> [Workout] {
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchWorkout(by id: UUID) -> Workout? {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    func fetchInProgressWorkout() -> Workout? {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.endTime == nil }
        )
        return try? modelContext.fetch(descriptor).first
    }

    func fetchWorkouts(from startDate: Date, to endDate: Date) -> [Workout] {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { workout in
                workout.startTime >= startDate && workout.startTime <= endDate
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Update

    func finishWorkout(_ workout: Workout) {
        workout.endTime = Date()
        try? modelContext.save()
    }

    func updateWorkoutName(_ workout: Workout, name: String) {
        workout.name = name
        try? modelContext.save()
    }

    func addExerciseToWorkout(_ workout: Workout, exercise: Exercise) -> WorkoutExercise {
        let order = workout.exercises.count
        let workoutExercise = WorkoutExercise(
            workout: workout,
            exercise: exercise,
            order: order
        )
        modelContext.insert(workoutExercise)
        workout.exercises.append(workoutExercise)
        try? modelContext.save()
        return workoutExercise
    }

    // MARK: - Delete

    func deleteWorkout(_ workout: Workout) {
        modelContext.delete(workout)
        try? modelContext.save()
    }

    func deleteWorkoutExercise(_ workoutExercise: WorkoutExercise) {
        modelContext.delete(workoutExercise)
        try? modelContext.save()
    }

    // MARK: - History Queries

    func getPreviousWorkoutExercise(for exercise: Exercise, before date: Date) -> WorkoutExercise? {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { workout in
                workout.startTime < date && workout.endTime != nil
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        guard let workouts = try? modelContext.fetch(descriptor) else {
            return nil
        }

        for workout in workouts {
            if let workoutExercise = workout.exercises.first(where: { $0.exercise?.id == exercise.id }) {
                return workoutExercise
            }
        }
        return nil
    }

    // MARK: - CSV Export

    func generateCSV() -> String {
        let workouts = fetchAllWorkouts()
        var csv = "Date,Workout,Exercise,Set,Weight (lbs),Reps,RPE,Set Type\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        for workout in workouts {
            guard workout.endTime != nil else { continue }
            let dateString = dateFormatter.string(from: workout.startTime)
            let workoutName = workout.displayName.replacingOccurrences(of: ",", with: ";")

            for workoutExercise in workout.exercises.sorted(by: { $0.order < $1.order }) {
                let exerciseName = (workoutExercise.exercise?.name ?? "Unknown")
                    .replacingOccurrences(of: ",", with: ";")

                for set in workoutExercise.sets.sorted(by: { $0.setNumber < $1.setNumber }) {
                    let weight = set.weight.map { String(format: "%.1f", $0) } ?? ""
                    let reps = set.reps.map { String($0) } ?? ""
                    let rpe = set.rpe.map { String($0) } ?? ""
                    let setType = set.setType.displayName

                    csv += "\(dateString),\(workoutName),\(exerciseName),\(set.setNumber),\(weight),\(reps),\(rpe),\(setType)\n"
                }
            }
        }

        return csv
    }

    // MARK: - Recent Exercises

    func fetchRecentExercises(limit: Int = 10) -> [Exercise] {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { workout in
                workout.endTime != nil
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        guard let workouts = try? modelContext.fetch(descriptor) else {
            return []
        }

        var seen = Set<UUID>()
        var recentExercises: [Exercise] = []

        for workout in workouts {
            let sorted = workout.exercises.sorted { $0.order < $1.order }
            for workoutExercise in sorted {
                guard let exercise = workoutExercise.exercise,
                      !exercise.isArchived,
                      !seen.contains(exercise.id) else { continue }
                seen.insert(exercise.id)
                recentExercises.append(exercise)
                if recentExercises.count >= limit { return recentExercises }
            }
        }

        return recentExercises
    }

    // MARK: - Save

    func save() {
        try? modelContext.save()
    }
}
