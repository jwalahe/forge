//
//  ExerciseRepository.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import Foundation
import SwiftData

@MainActor
class ExerciseRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func createExercise(
        name: String,
        muscleGroup: Exercise.MuscleGroup,
        equipment: Exercise.Equipment,
        isCustom: Bool = true
    ) -> Exercise {
        let exercise = Exercise(
            name: name,
            muscleGroup: muscleGroup,
            equipment: equipment,
            isCustom: isCustom
        )
        modelContext.insert(exercise)
        try? modelContext.save()
        return exercise
    }

    // MARK: - Read

    func fetchAllExercises() -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchExercises(by muscleGroup: Exercise.MuscleGroup) -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { exercise in
                exercise.muscleGroup == muscleGroup && !exercise.isArchived
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func searchExercises(query: String) -> [Exercise] {
        let lowercaseQuery = query.lowercased()
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { !$0.isArchived }
        )
        guard let allExercises = try? modelContext.fetch(descriptor) else {
            return []
        }
        return allExercises.filter { $0.name.lowercased().contains(lowercaseQuery) }
    }

    func fetchExercise(by id: UUID) -> Exercise? {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    // MARK: - Update

    func updateExercise(_ exercise: Exercise, name: String? = nil, muscleGroup: Exercise.MuscleGroup? = nil) {
        if let name = name {
            exercise.name = name
        }
        if let muscleGroup = muscleGroup {
            exercise.muscleGroup = muscleGroup
        }
        try? modelContext.save()
    }

    func archiveExercise(_ exercise: Exercise) {
        exercise.isArchived = true
        try? modelContext.save()
    }

    // MARK: - Delete

    func deleteExercise(_ exercise: Exercise) {
        modelContext.delete(exercise)
        try? modelContext.save()
    }

    // MARK: - Default Exercises

    func seedDefaultExercises() {
        let existingCount = fetchAllExercises().count
        guard existingCount == 0 else { return }

        let defaultExercises: [(String, Exercise.MuscleGroup, Exercise.Equipment)] = [
            // Chest
            ("Bench Press", .chest, .barbell),
            ("Incline Bench Press", .chest, .barbell),
            ("Decline Bench Press", .chest, .barbell),
            ("Dumbbell Press", .chest, .dumbbell),
            ("Incline Dumbbell Press", .chest, .dumbbell),
            ("Dumbbell Fly", .chest, .dumbbell),
            ("Cable Fly", .chest, .cable),
            ("Push-Up", .chest, .bodyweight),
            ("Chest Dip", .chest, .bodyweight),

            // Back
            ("Deadlift", .back, .barbell),
            ("Barbell Row", .back, .barbell),
            ("Dumbbell Row", .back, .dumbbell),
            ("Lat Pulldown", .back, .cable),
            ("Pull-Up", .back, .bodyweight),
            ("Chin-Up", .back, .bodyweight),
            ("Seated Cable Row", .back, .cable),
            ("T-Bar Row", .back, .barbell),
            ("Face Pull", .back, .cable),

            // Shoulders
            ("Overhead Press", .shoulders, .barbell),
            ("Dumbbell Shoulder Press", .shoulders, .dumbbell),
            ("Lateral Raise", .shoulders, .dumbbell),
            ("Front Raise", .shoulders, .dumbbell),
            ("Rear Delt Fly", .shoulders, .dumbbell),
            ("Upright Row", .shoulders, .barbell),
            ("Arnold Press", .shoulders, .dumbbell),
            ("Shrug", .shoulders, .barbell),

            // Biceps
            ("Barbell Curl", .biceps, .barbell),
            ("Dumbbell Curl", .biceps, .dumbbell),
            ("Hammer Curl", .biceps, .dumbbell),
            ("Preacher Curl", .biceps, .barbell),
            ("Concentration Curl", .biceps, .dumbbell),
            ("Cable Curl", .biceps, .cable),

            // Triceps
            ("Tricep Pushdown", .triceps, .cable),
            ("Skull Crusher", .triceps, .barbell),
            ("Overhead Tricep Extension", .triceps, .dumbbell),
            ("Dip", .triceps, .bodyweight),
            ("Close-Grip Bench Press", .triceps, .barbell),
            ("Tricep Kickback", .triceps, .dumbbell),

            // Legs (Quads)
            ("Squat", .quads, .barbell),
            ("Front Squat", .quads, .barbell),
            ("Leg Press", .quads, .machine),
            ("Leg Extension", .quads, .machine),
            ("Hack Squat", .quads, .machine),
            ("Goblet Squat", .quads, .dumbbell),

            // Legs (Hamstrings)
            ("Romanian Deadlift", .hamstrings, .barbell),
            ("Leg Curl", .hamstrings, .machine),
            ("Stiff-Leg Deadlift", .hamstrings, .barbell),
            ("Good Morning", .hamstrings, .barbell),

            // Legs (Glutes)
            ("Hip Thrust", .glutes, .barbell),
            ("Bulgarian Split Squat", .glutes, .dumbbell),
            ("Lunge", .glutes, .dumbbell),
            ("Walking Lunge", .glutes, .dumbbell),
            ("Glute Bridge", .glutes, .bodyweight),

            // Calves
            ("Standing Calf Raise", .calves, .machine),
            ("Seated Calf Raise", .calves, .machine),

            // Core
            ("Plank", .core, .bodyweight),
            ("Crunch", .core, .bodyweight),
            ("Leg Raise", .core, .bodyweight),
            ("Cable Crunch", .core, .cable),
            ("Ab Wheel Rollout", .core, .other),
            ("Russian Twist", .core, .bodyweight),
            ("Hanging Knee Raise", .core, .bodyweight),
        ]

        for (name, muscleGroup, equipment) in defaultExercises {
            _ = createExercise(
                name: name,
                muscleGroup: muscleGroup,
                equipment: equipment,
                isCustom: false
            )
        }
    }
}
