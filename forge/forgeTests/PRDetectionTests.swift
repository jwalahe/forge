//
//  PRDetectionTests.swift
//  forgeTests
//
//  Tests Brzycki formula correctness and PR detection logic.
//  PR detection is a core trust signal — wrong PRs erode user confidence.
//

import Testing
import Foundation
import SwiftData
@testable import forge

@MainActor
@Suite("PR Detection Tests")
struct PRDetectionTests {
    let container: ModelContainer
    let context: ModelContext
    let viewModel: ActiveWorkoutViewModel

    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Workout.self, WorkoutExercise.self, ExerciseSet.self,
                 Exercise.self, Template.self, TemplateExercise.self,
            configurations: config
        )
        context = container.mainContext
        viewModel = ActiveWorkoutViewModel(modelContext: context)
    }

    // MARK: - Helpers

    private func createExercise(name: String = "Bench Press") -> Exercise {
        let exercise = Exercise(name: name, muscleGroup: .chest, equipment: .barbell)
        context.insert(exercise)
        return exercise
    }

    private func createCompletedWorkout(
        exercise: Exercise,
        sets: [(weight: Double, reps: Int)],
        daysAgo: Int = 1
    ) {
        let startTime = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        let workout = Workout(startTime: startTime, endTime: startTime.addingTimeInterval(3600))
        context.insert(workout)

        let workoutExercise = WorkoutExercise(workout: workout, exercise: exercise, order: 0)
        context.insert(workoutExercise)
        workout.exercises.append(workoutExercise)

        for (index, setData) in sets.enumerated() {
            let set = ExerciseSet(
                workoutExercise: workoutExercise,
                setNumber: index + 1,
                weight: setData.weight,
                reps: setData.reps,
                completedAt: startTime
            )
            context.insert(set)
            workoutExercise.sets.append(set)
        }

        try? context.save()
    }

    private func brzycki1RM(weight: Double, reps: Int) -> Double {
        weight * (36.0 / (37.0 - Double(reps)))
    }

    // MARK: - Brzycki Formula Correctness

    @Test("Brzycki formula: 185 x 10 = e1RM ~246.7")
    func brzycki_185x10() {
        let e1RM = brzycki1RM(weight: 185, reps: 10)
        // 185 * (36 / (37 - 10)) = 185 * (36 / 27) = 185 * 1.333... = 246.666...
        #expect(abs(e1RM - 246.666) < 0.1)
    }

    @Test("Brzycki formula: 185 x 8 = e1RM ~229.7")
    func brzycki_185x8() {
        let e1RM = brzycki1RM(weight: 185, reps: 8)
        // 185 * (36 / (37 - 8)) = 185 * (36 / 29) = 185 * 1.2413... = 229.65...
        #expect(abs(e1RM - 229.655) < 0.1)
    }

    @Test("Brzycki formula: reps == 1 returns actual weight (1RM = weight)")
    func brzycki_1rep() {
        let e1RM = brzycki1RM(weight: 225, reps: 1)
        // 225 * (36 / (37 - 1)) = 225 * (36 / 36) = 225 * 1.0 = 225
        #expect(e1RM == 225.0)
    }

    @Test("Brzycki formula: reps == 36 produces large but finite value")
    func brzycki_36reps() {
        let e1RM = brzycki1RM(weight: 100, reps: 36)
        // 100 * (36 / (37 - 36)) = 100 * 36 = 3600
        #expect(e1RM == 3600.0)
    }

    @Test("Brzycki formula: reps == 37 causes division by zero (infinity)")
    func brzycki_37reps_divisionByZero() {
        let e1RM = brzycki1RM(weight: 100, reps: 37)
        // 100 * (36 / (37 - 37)) = 100 * (36 / 0) = infinity
        #expect(e1RM.isInfinite)
    }

    @Test("Brzycki formula: reps > 37 produces negative value")
    func brzycki_over37reps_negative() {
        let e1RM = brzycki1RM(weight: 100, reps: 38)
        // 100 * (36 / (37 - 38)) = 100 * (36 / -1) = -3600
        #expect(e1RM < 0)
    }

    // MARK: - PR Detection via ViewModel

    @Test("First-ever set for an exercise is always a PR")
    func firstSetIsAlwaysPR() throws {
        let benchPress = createExercise(name: "Bench Press")

        viewModel.startNewWorkout()
        viewModel.addExercise(benchPress)

        guard let workoutExercise = viewModel.currentWorkout?.exercises.first else {
            Issue.record("No workout exercise found")
            return
        }

        // Update the auto-created set with values and complete it
        guard let set = workoutExercise.sets.first else {
            Issue.record("No set found")
            return
        }
        viewModel.updateSet(set, weight: 135, reps: 10)
        viewModel.completeSet(set)

        #expect(set.isPersonalRecord == true)
    }

    @Test("Set beating previous e1RM is marked as PR")
    func setBeatsPreviousE1RM_isPR() throws {
        let benchPress = createExercise(name: "Bench Press")

        // Previous workout: 185 x 8 → e1RM = 229.7
        createCompletedWorkout(exercise: benchPress, sets: [(185, 8)], daysAgo: 2)

        viewModel.startNewWorkout()
        viewModel.addExercise(benchPress)

        guard let workoutExercise = viewModel.currentWorkout?.exercises.first,
              let set = workoutExercise.sets.first else {
            Issue.record("No set found")
            return
        }

        // 185 x 10 → e1RM = 246.7 > 229.7
        viewModel.updateSet(set, weight: 185, reps: 10)
        viewModel.completeSet(set)

        #expect(set.isPersonalRecord == true)
    }

    @Test("Set below previous e1RM is NOT marked as PR")
    func setBelowPreviousE1RM_isNotPR() throws {
        let benchPress = createExercise(name: "Bench Press")

        // Previous workout: 185 x 10 → e1RM = 246.7
        createCompletedWorkout(exercise: benchPress, sets: [(185, 10)], daysAgo: 2)

        viewModel.startNewWorkout()
        viewModel.addExercise(benchPress)

        guard let workoutExercise = viewModel.currentWorkout?.exercises.first,
              let set = workoutExercise.sets.first else {
            Issue.record("No set found")
            return
        }

        // 185 x 8 → e1RM = 229.7 < 246.7
        viewModel.updateSet(set, weight: 185, reps: 8)
        viewModel.completeSet(set)

        #expect(set.isPersonalRecord == false)
    }

    @Test("PR detection compares against ALL previous sets, not just last workout")
    func prDetection_comparesAllHistory() throws {
        let benchPress = createExercise(name: "Bench Press")

        // Workout 2 weeks ago: 200 x 5 → e1RM = 225
        createCompletedWorkout(exercise: benchPress, sets: [(200, 5)], daysAgo: 14)

        // Workout 1 week ago (regression): 185 x 5 → e1RM = 208.1
        createCompletedWorkout(exercise: benchPress, sets: [(185, 5)], daysAgo: 7)

        viewModel.startNewWorkout()
        viewModel.addExercise(benchPress)

        guard let workoutExercise = viewModel.currentWorkout?.exercises.first,
              let set = workoutExercise.sets.first else {
            Issue.record("No set found")
            return
        }

        // 195 x 5 → e1RM = 219.4 < 225 (the old best)
        viewModel.updateSet(set, weight: 195, reps: 5)
        viewModel.completeSet(set)

        #expect(set.isPersonalRecord == false)
    }

    @Test("Higher weight at same reps beats previous PR")
    func higherWeightSameReps_isPR() throws {
        let benchPress = createExercise(name: "Bench Press")

        // Previous: 185 x 5
        createCompletedWorkout(exercise: benchPress, sets: [(185, 5)], daysAgo: 2)

        viewModel.startNewWorkout()
        viewModel.addExercise(benchPress)

        guard let workoutExercise = viewModel.currentWorkout?.exercises.first,
              let set = workoutExercise.sets.first else {
            Issue.record("No set found")
            return
        }

        // 190 x 5 → higher e1RM than 185 x 5
        viewModel.updateSet(set, weight: 190, reps: 5)
        viewModel.completeSet(set)

        #expect(set.isPersonalRecord == true)
    }

    @Test("PR detection skips sets with nil weight or reps")
    func prDetection_skipsNilValues() throws {
        let benchPress = createExercise(name: "Bench Press")

        viewModel.startNewWorkout()
        viewModel.addExercise(benchPress)

        guard let workoutExercise = viewModel.currentWorkout?.exercises.first,
              let set = workoutExercise.sets.first else {
            Issue.record("No set found")
            return
        }

        // Complete set with nil weight — should not be marked PR
        viewModel.updateSet(set, weight: nil, reps: 10)
        viewModel.completeSet(set)

        #expect(set.isPersonalRecord == false)
    }

    @Test("PR detection skips sets with zero reps")
    func prDetection_skipsZeroReps() throws {
        let benchPress = createExercise(name: "Bench Press")

        viewModel.startNewWorkout()
        viewModel.addExercise(benchPress)

        guard let workoutExercise = viewModel.currentWorkout?.exercises.first,
              let set = workoutExercise.sets.first else {
            Issue.record("No set found")
            return
        }

        // Complete set with 0 reps — should not be marked PR
        viewModel.updateSet(set, weight: 185, reps: 0)
        viewModel.completeSet(set)

        #expect(set.isPersonalRecord == false)
    }
}
