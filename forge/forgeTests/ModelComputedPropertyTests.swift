//
//  ModelComputedPropertyTests.swift
//  forgeTests
//
//  Tests computed properties on Workout, WorkoutExercise, and ExerciseSet models.
//  These drive the workout summary, history display, and stats screens.
//

import Testing
import Foundation
import SwiftData
@testable import forge

@MainActor
@Suite("Model Computed Property Tests")
struct ModelComputedPropertyTests {
    let container: ModelContainer
    let context: ModelContext

    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Workout.self, WorkoutExercise.self, ExerciseSet.self,
                 Exercise.self, Template.self, TemplateExercise.self,
            configurations: config
        )
        context = container.mainContext
    }

    // MARK: - Helpers

    private func createExercise(name: String = "Bench Press") -> Exercise {
        let exercise = Exercise(name: name, muscleGroup: .chest, equipment: .barbell)
        context.insert(exercise)
        return exercise
    }

    // MARK: - ExerciseSet.isCompleted

    @Test("isCompleted: true when completedAt, weight, and reps all present")
    func exerciseSet_isCompleted_allPresent() {
        let set = ExerciseSet(setNumber: 1, weight: 185, reps: 8, completedAt: Date())
        context.insert(set)

        #expect(set.isCompleted == true)
    }

    @Test("isCompleted: false when completedAt is nil")
    func exerciseSet_isCompleted_noCompletedAt() {
        let set = ExerciseSet(setNumber: 1, weight: 185, reps: 8, completedAt: nil)
        context.insert(set)

        #expect(set.isCompleted == false)
    }

    @Test("isCompleted: false when weight is nil")
    func exerciseSet_isCompleted_noWeight() {
        let set = ExerciseSet(setNumber: 1, weight: nil, reps: 8, completedAt: Date())
        context.insert(set)

        #expect(set.isCompleted == false)
    }

    @Test("isCompleted: false when reps is nil")
    func exerciseSet_isCompleted_noReps() {
        let set = ExerciseSet(setNumber: 1, weight: 185, reps: nil, completedAt: Date())
        context.insert(set)

        #expect(set.isCompleted == false)
    }

    @Test("isCompleted: false when all values are nil")
    func exerciseSet_isCompleted_allNil() {
        let set = ExerciseSet(setNumber: 1, weight: nil, reps: nil, completedAt: nil)
        context.insert(set)

        #expect(set.isCompleted == false)
    }

    // MARK: - ExerciseSet.volume

    @Test("volume: weight × reps when both present")
    func exerciseSet_volume_calculated() {
        let set = ExerciseSet(setNumber: 1, weight: 185, reps: 8)
        context.insert(set)

        #expect(set.volume == 1480.0) // 185 * 8
    }

    @Test("volume: 0 when weight is nil")
    func exerciseSet_volume_nilWeight() {
        let set = ExerciseSet(setNumber: 1, weight: nil, reps: 8)
        context.insert(set)

        #expect(set.volume == 0)
    }

    @Test("volume: 0 when reps is nil")
    func exerciseSet_volume_nilReps() {
        let set = ExerciseSet(setNumber: 1, weight: 185, reps: nil)
        context.insert(set)

        #expect(set.volume == 0)
    }

    @Test("volume: 0 when both nil")
    func exerciseSet_volume_bothNil() {
        let set = ExerciseSet(setNumber: 1, weight: nil, reps: nil)
        context.insert(set)

        #expect(set.volume == 0)
    }

    // MARK: - WorkoutExercise.completedSets

    @Test("completedSets: only returns sets where isCompleted is true")
    func workoutExercise_completedSets() {
        let exercise = createExercise()
        let workoutExercise = WorkoutExercise(exercise: exercise, order: 0)
        context.insert(workoutExercise)

        // Completed set
        let completedSet = ExerciseSet(
            workoutExercise: workoutExercise, setNumber: 1,
            weight: 185, reps: 8, completedAt: Date()
        )
        context.insert(completedSet)
        workoutExercise.sets.append(completedSet)

        // Incomplete set (no completedAt)
        let incompleteSet = ExerciseSet(
            workoutExercise: workoutExercise, setNumber: 2,
            weight: 185, reps: nil, completedAt: nil
        )
        context.insert(incompleteSet)
        workoutExercise.sets.append(incompleteSet)

        #expect(workoutExercise.completedSets.count == 1)
    }

    // MARK: - WorkoutExercise.totalVolume

    @Test("totalVolume: sum of completed sets' volumes only")
    func workoutExercise_totalVolume() {
        let exercise = createExercise()
        let workoutExercise = WorkoutExercise(exercise: exercise, order: 0)
        context.insert(workoutExercise)

        let set1 = ExerciseSet(
            workoutExercise: workoutExercise, setNumber: 1,
            weight: 185, reps: 8, completedAt: Date()
        ) // 1480
        context.insert(set1)
        workoutExercise.sets.append(set1)

        let set2 = ExerciseSet(
            workoutExercise: workoutExercise, setNumber: 2,
            weight: 185, reps: 6, completedAt: Date()
        ) // 1110
        context.insert(set2)
        workoutExercise.sets.append(set2)

        // Incomplete — should not count
        let set3 = ExerciseSet(
            workoutExercise: workoutExercise, setNumber: 3,
            weight: 185, reps: nil, completedAt: nil
        )
        context.insert(set3)
        workoutExercise.sets.append(set3)

        #expect(workoutExercise.totalVolume == 2590.0) // 1480 + 1110
    }

    // MARK: - Workout.totalVolume

    @Test("totalVolume: sum across all exercises' completed sets")
    func workout_totalVolume() {
        let workout = Workout()
        context.insert(workout)

        let bench = createExercise(name: "Bench Press")
        let we1 = WorkoutExercise(workout: workout, exercise: bench, order: 0)
        context.insert(we1)
        workout.exercises.append(we1)

        let set1 = ExerciseSet(
            workoutExercise: we1, setNumber: 1,
            weight: 185, reps: 8, completedAt: Date()
        ) // 1480
        context.insert(set1)
        we1.sets.append(set1)

        let squat = createExercise(name: "Squat")
        let we2 = WorkoutExercise(workout: workout, exercise: squat, order: 1)
        context.insert(we2)
        workout.exercises.append(we2)

        let set2 = ExerciseSet(
            workoutExercise: we2, setNumber: 1,
            weight: 225, reps: 5, completedAt: Date()
        ) // 1125
        context.insert(set2)
        we2.sets.append(set2)

        #expect(workout.totalVolume == 2605.0) // 1480 + 1125
    }

    @Test("totalVolume: 0 for empty workout")
    func workout_totalVolume_empty() {
        let workout = Workout()
        context.insert(workout)

        #expect(workout.totalVolume == 0)
    }

    // MARK: - Workout.totalSets

    @Test("totalSets: counts only completed sets across all exercises")
    func workout_totalSets() {
        let workout = Workout()
        context.insert(workout)

        let bench = createExercise(name: "Bench Press")
        let we1 = WorkoutExercise(workout: workout, exercise: bench, order: 0)
        context.insert(we1)
        workout.exercises.append(we1)

        // 2 completed + 1 incomplete
        for i in 1...3 {
            let set = ExerciseSet(
                workoutExercise: we1, setNumber: i,
                weight: 185, reps: i <= 2 ? 8 : nil,
                completedAt: i <= 2 ? Date() : nil
            )
            context.insert(set)
            we1.sets.append(set)
        }

        #expect(workout.totalSets == 2)
    }

    @Test("totalSets: 0 for workout with zero exercises")
    func workout_totalSets_empty() {
        let workout = Workout()
        context.insert(workout)

        #expect(workout.totalSets == 0)
    }

    // MARK: - Workout.displayName

    @Test("displayName: returns custom name when set")
    func workout_displayName_customName() {
        let workout = Workout(name: "Push Day A")
        context.insert(workout)

        #expect(workout.displayName == "Push Day A")
    }

    @Test("displayName: 'Workout' when no exercises and no name")
    func workout_displayName_noExercises() {
        let workout = Workout()
        context.insert(workout)

        #expect(workout.displayName == "Workout")
    }

    @Test("displayName: single exercise name when one exercise")
    func workout_displayName_oneExercise() {
        let workout = Workout()
        context.insert(workout)

        let bench = createExercise(name: "Bench Press")
        let we = WorkoutExercise(workout: workout, exercise: bench, order: 0)
        context.insert(we)
        workout.exercises.append(we)

        #expect(workout.displayName == "Bench Press")
    }

    @Test("displayName: 'X & Y' when two exercises")
    func workout_displayName_twoExercises() {
        let workout = Workout()
        context.insert(workout)

        let bench = createExercise(name: "Bench Press")
        let squat = createExercise(name: "Squat")

        let we1 = WorkoutExercise(workout: workout, exercise: bench, order: 0)
        let we2 = WorkoutExercise(workout: workout, exercise: squat, order: 1)
        context.insert(we1)
        context.insert(we2)
        workout.exercises.append(we1)
        workout.exercises.append(we2)

        #expect(workout.displayName == "Bench Press & Squat")
    }

    @Test("displayName: 'X, Y...' when three or more exercises")
    func workout_displayName_threeExercises() {
        let workout = Workout()
        context.insert(workout)

        let bench = createExercise(name: "Bench Press")
        let squat = createExercise(name: "Squat")
        let row = createExercise(name: "Barbell Row")

        let we1 = WorkoutExercise(workout: workout, exercise: bench, order: 0)
        let we2 = WorkoutExercise(workout: workout, exercise: squat, order: 1)
        let we3 = WorkoutExercise(workout: workout, exercise: row, order: 2)
        context.insert(we1)
        context.insert(we2)
        context.insert(we3)
        workout.exercises.append(we1)
        workout.exercises.append(we2)
        workout.exercises.append(we3)

        #expect(workout.displayName == "Bench Press, Squat...")
    }

    @Test("displayName: empty string name falls back to auto-generation")
    func workout_displayName_emptyStringName() {
        let workout = Workout(name: "")
        context.insert(workout)

        #expect(workout.displayName == "Workout")
    }

    // MARK: - Workout.isInProgress

    @Test("isInProgress: true when endTime is nil")
    func workout_isInProgress_true() {
        let workout = Workout(endTime: nil)
        context.insert(workout)

        #expect(workout.isInProgress == true)
    }

    @Test("isInProgress: false when endTime is set")
    func workout_isInProgress_false() {
        let workout = Workout(endTime: Date())
        context.insert(workout)

        #expect(workout.isInProgress == false)
    }

    // MARK: - Workout.duration

    @Test("duration: calculated when endTime is set")
    func workout_duration_calculated() {
        let start = Date()
        let end = start.addingTimeInterval(2700) // 45 min
        let workout = Workout(startTime: start, endTime: end)
        context.insert(workout)

        #expect(workout.duration == 2700)
    }

    @Test("duration: nil when endTime is nil")
    func workout_duration_nil() {
        let workout = Workout(endTime: nil)
        context.insert(workout)

        #expect(workout.duration == nil)
    }

    // MARK: - Workout.personalRecordsCount

    @Test("personalRecordsCount: counts sets flagged as PR")
    func workout_personalRecordsCount() {
        let workout = Workout()
        context.insert(workout)

        let bench = createExercise(name: "Bench Press")
        let we = WorkoutExercise(workout: workout, exercise: bench, order: 0)
        context.insert(we)
        workout.exercises.append(we)

        let prSet = ExerciseSet(
            workoutExercise: we, setNumber: 1,
            weight: 225, reps: 5, completedAt: Date(), isPersonalRecord: true
        )
        let normalSet = ExerciseSet(
            workoutExercise: we, setNumber: 2,
            weight: 225, reps: 4, completedAt: Date(), isPersonalRecord: false
        )
        context.insert(prSet)
        context.insert(normalSet)
        we.sets.append(prSet)
        we.sets.append(normalSet)

        #expect(workout.personalRecordsCount == 1)
    }

    // MARK: - SetType.displayName

    @Test("SetType displayName values are correct")
    func setType_displayNames() {
        #expect(ExerciseSet.SetType.warmup.displayName == "Warmup")
        #expect(ExerciseSet.SetType.working.displayName == "Working")
        #expect(ExerciseSet.SetType.dropSet.displayName == "Drop Set")
        #expect(ExerciseSet.SetType.toFailure.displayName == "To Failure")
    }

    // MARK: - Exercise Enum displayNames

    @Test("MuscleGroup displayName values are correct")
    func muscleGroup_displayNames() {
        #expect(Exercise.MuscleGroup.chest.displayName == "Chest")
        #expect(Exercise.MuscleGroup.back.displayName == "Back")
        #expect(Exercise.MuscleGroup.quads.displayName == "Legs (Quads)")
        #expect(Exercise.MuscleGroup.fullBody.displayName == "Full Body")
    }

    @Test("Equipment displayName values are correct")
    func equipment_displayNames() {
        #expect(Exercise.Equipment.barbell.displayName == "Barbell")
        #expect(Exercise.Equipment.bodyweight.displayName == "Bodyweight")
        #expect(Exercise.Equipment.other.displayName == "Other")
    }

    // MARK: - Template.exerciseCount

    @Test("Template exerciseCount matches number of TemplateExercises")
    func template_exerciseCount() {
        let template = Template(name: "Push Day")
        context.insert(template)

        for i in 0..<3 {
            let exercise = createExercise(name: "Exercise \(i)")
            let te = TemplateExercise(template: template, exercise: exercise, order: i)
            context.insert(te)
            template.exercises.append(te)
        }

        #expect(template.exerciseCount == 3)
    }
}
