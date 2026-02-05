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
        // Fetch all exercise names (including archived) to avoid duplicates
        let descriptor = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)])
        let existingNames = Set((try? modelContext.fetch(descriptor))?.map(\.name) ?? [])

        let defaultExercises: [(String, Exercise.MuscleGroup, Exercise.Equipment)] = [
            // MARK: Chest (18)
            ("Bench Press", .chest, .barbell),
            ("Cable Crossover", .chest, .cable),
            ("Cable Fly", .chest, .cable),
            ("Chest Dip", .chest, .bodyweight),
            ("Chest Press Machine", .chest, .machine),
            ("Decline Bench Press", .chest, .barbell),
            ("Decline Dumbbell Press", .chest, .dumbbell),
            ("Dumbbell Fly", .chest, .dumbbell),
            ("Dumbbell Press", .chest, .dumbbell),
            ("Dumbbell Pullover", .chest, .dumbbell),
            ("Floor Press", .chest, .barbell),
            ("Incline Bench Press", .chest, .barbell),
            ("Incline Cable Fly", .chest, .cable),
            ("Incline Dumbbell Fly", .chest, .dumbbell),
            ("Incline Dumbbell Press", .chest, .dumbbell),
            ("Machine Fly", .chest, .machine),
            ("Push-Up", .chest, .bodyweight),
            ("Smith Machine Bench Press", .chest, .machine),

            // MARK: Back (19)
            ("Barbell Row", .back, .barbell),
            ("Cable Pullover", .back, .cable),
            ("Chest-Supported Row", .back, .machine),
            ("Chin-Up", .back, .bodyweight),
            ("Close-Grip Lat Pulldown", .back, .cable),
            ("Deadlift", .back, .barbell),
            ("Dumbbell Row", .back, .dumbbell),
            ("Face Pull", .back, .cable),
            ("Inverted Row", .back, .bodyweight),
            ("Lat Pulldown", .back, .cable),
            ("Machine Row", .back, .machine),
            ("Pendlay Row", .back, .barbell),
            ("Pull-Up", .back, .bodyweight),
            ("Rack Pull", .back, .barbell),
            ("Reverse Grip Lat Pulldown", .back, .cable),
            ("Seated Cable Row", .back, .cable),
            ("Single-Arm Cable Row", .back, .cable),
            ("Straight-Arm Pulldown", .back, .cable),
            ("T-Bar Row", .back, .barbell),

            // MARK: Shoulders (17)
            ("Arnold Press", .shoulders, .dumbbell),
            ("Barbell Front Raise", .shoulders, .barbell),
            ("Cable Lateral Raise", .shoulders, .cable),
            ("Cable Rear Delt Fly", .shoulders, .cable),
            ("Dumbbell Shoulder Press", .shoulders, .dumbbell),
            ("Dumbbell Shrug", .shoulders, .dumbbell),
            ("Front Raise", .shoulders, .dumbbell),
            ("Landmine Press", .shoulders, .barbell),
            ("Lateral Raise", .shoulders, .dumbbell),
            ("Machine Lateral Raise", .shoulders, .machine),
            ("Machine Shoulder Press", .shoulders, .machine),
            ("Overhead Press", .shoulders, .barbell),
            ("Push Press", .shoulders, .barbell),
            ("Rear Delt Fly", .shoulders, .dumbbell),
            ("Reverse Machine Fly", .shoulders, .machine),
            ("Shrug", .shoulders, .barbell),
            ("Upright Row", .shoulders, .barbell),

            // MARK: Biceps (13)
            ("Barbell Curl", .biceps, .barbell),
            ("Cable Curl", .biceps, .cable),
            ("Cable Hammer Curl", .biceps, .cable),
            ("Concentration Curl", .biceps, .dumbbell),
            ("Dumbbell Curl", .biceps, .dumbbell),
            ("Dumbbell Preacher Curl", .biceps, .dumbbell),
            ("EZ-Bar Curl", .biceps, .barbell),
            ("Hammer Curl", .biceps, .dumbbell),
            ("Incline Dumbbell Curl", .biceps, .dumbbell),
            ("Machine Curl", .biceps, .machine),
            ("Preacher Curl", .biceps, .barbell),
            ("Reverse Curl", .biceps, .barbell),
            ("Spider Curl", .biceps, .dumbbell),

            // MARK: Triceps (13)
            ("Bench Dip", .triceps, .bodyweight),
            ("Cable Overhead Tricep Extension", .triceps, .cable),
            ("Close-Grip Bench Press", .triceps, .barbell),
            ("Diamond Push-Up", .triceps, .bodyweight),
            ("Dip", .triceps, .bodyweight),
            ("Machine Tricep Extension", .triceps, .machine),
            ("Overhead Tricep Extension", .triceps, .dumbbell),
            ("Rope Pushdown", .triceps, .cable),
            ("Single-Arm Tricep Pushdown", .triceps, .cable),
            ("Skull Crusher", .triceps, .barbell),
            ("Tricep Dip Machine", .triceps, .machine),
            ("Tricep Kickback", .triceps, .dumbbell),
            ("Tricep Pushdown", .triceps, .cable),

            // MARK: Legs - Quads (15)
            ("Belt Squat", .quads, .machine),
            ("Box Squat", .quads, .barbell),
            ("Front Squat", .quads, .barbell),
            ("Goblet Squat", .quads, .dumbbell),
            ("Hack Squat", .quads, .machine),
            ("Landmine Squat", .quads, .barbell),
            ("Leg Extension", .quads, .machine),
            ("Leg Press", .quads, .machine),
            ("Pendulum Squat", .quads, .machine),
            ("Pistol Squat", .quads, .bodyweight),
            ("Reverse Lunge", .quads, .dumbbell),
            ("Sissy Squat", .quads, .bodyweight),
            ("Smith Machine Squat", .quads, .machine),
            ("Squat", .quads, .barbell),
            ("Step-Up", .quads, .dumbbell),

            // MARK: Legs - Hamstrings (11)
            ("Dumbbell Good Morning", .hamstrings, .dumbbell),
            ("Dumbbell Romanian Deadlift", .hamstrings, .dumbbell),
            ("Glute-Ham Raise", .hamstrings, .bodyweight),
            ("Good Morning", .hamstrings, .barbell),
            ("Leg Curl", .hamstrings, .machine),
            ("Nordic Curl", .hamstrings, .bodyweight),
            ("Romanian Deadlift", .hamstrings, .barbell),
            ("Seated Leg Curl", .hamstrings, .machine),
            ("Single-Leg Deadlift", .hamstrings, .dumbbell),
            ("Stiff-Leg Deadlift", .hamstrings, .barbell),
            ("Sumo Deadlift", .hamstrings, .barbell),

            // MARK: Legs - Glutes (13)
            ("Bulgarian Split Squat", .glutes, .dumbbell),
            ("Cable Kickback", .glutes, .cable),
            ("Cable Pull-Through", .glutes, .cable),
            ("Curtsy Lunge", .glutes, .dumbbell),
            ("Donkey Kick", .glutes, .bodyweight),
            ("Glute Bridge", .glutes, .bodyweight),
            ("Hip Abduction Machine", .glutes, .machine),
            ("Hip Thrust", .glutes, .barbell),
            ("Lateral Lunge", .glutes, .dumbbell),
            ("Lunge", .glutes, .dumbbell),
            ("Single-Leg Hip Thrust", .glutes, .bodyweight),
            ("Sumo Squat", .glutes, .dumbbell),
            ("Walking Lunge", .glutes, .dumbbell),

            // MARK: Calves (8)
            ("Barbell Calf Raise", .calves, .barbell),
            ("Calf Press on Leg Press", .calves, .machine),
            ("Donkey Calf Raise", .calves, .machine),
            ("Dumbbell Calf Raise", .calves, .dumbbell),
            ("Seated Calf Raise", .calves, .machine),
            ("Single-Leg Calf Raise", .calves, .bodyweight),
            ("Smith Machine Calf Raise", .calves, .machine),
            ("Standing Calf Raise", .calves, .machine),

            // MARK: Core (16)
            ("Ab Wheel Rollout", .core, .other),
            ("Bicycle Crunch", .core, .bodyweight),
            ("Cable Crunch", .core, .cable),
            ("Cable Woodchop", .core, .cable),
            ("Crunch", .core, .bodyweight),
            ("Dead Bug", .core, .bodyweight),
            ("Decline Sit-Up", .core, .bodyweight),
            ("Dragon Flag", .core, .bodyweight),
            ("Hanging Knee Raise", .core, .bodyweight),
            ("Hanging Leg Raise", .core, .bodyweight),
            ("Leg Raise", .core, .bodyweight),
            ("Pallof Press", .core, .cable),
            ("Plank", .core, .bodyweight),
            ("Russian Twist", .core, .bodyweight),
            ("Side Plank", .core, .bodyweight),
            ("V-Up", .core, .bodyweight),

            // MARK: Full Body (9)
            ("Barbell Clean", .fullBody, .barbell),
            ("Barbell Snatch", .fullBody, .barbell),
            ("Burpee", .fullBody, .bodyweight),
            ("Clean and Press", .fullBody, .barbell),
            ("Dumbbell Snatch", .fullBody, .dumbbell),
            ("Farmer's Walk", .fullBody, .dumbbell),
            ("Kettlebell Swing", .fullBody, .other),
            ("Thruster", .fullBody, .barbell),
            ("Turkish Get-Up", .fullBody, .other),
        ]

        for (name, muscleGroup, equipment) in defaultExercises {
            guard !existingNames.contains(name) else { continue }
            _ = createExercise(
                name: name,
                muscleGroup: muscleGroup,
                equipment: equipment,
                isCustom: false
            )
        }
    }
}
