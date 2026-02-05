//
//  ProgressIndicatorTests.swift
//  forgeTests
//
//  Tests progress indicator logic (green ↑ / red ↓ / none).
//  Wrong arrows mislead users about their progress trajectory.
//

import Testing
import Foundation
import SwiftData
@testable import forge

@MainActor
@Suite("Progress Indicator Tests")
struct ProgressIndicatorTests {
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

    private func makeSet(weight: Double?, reps: Int?) -> ExerciseSet {
        let set = ExerciseSet(setNumber: 1, weight: weight, reps: reps)
        context.insert(set)
        return set
    }

    // MARK: - Weight Increased

    @Test("Weight increased at same reps → up")
    func weightUp_sameReps_isUp() {
        let current = makeSet(weight: 190, reps: 8)
        let previous = makeSet(weight: 185, reps: 8)

        let result = viewModel.getProgressIndicator(currentSet: current, previousSet: previous)
        #expect(result == .up)
    }

    @Test("Weight increased with fewer reps → up")
    func weightUp_fewerReps_isUp() {
        let current = makeSet(weight: 200, reps: 5)
        let previous = makeSet(weight: 185, reps: 8)

        let result = viewModel.getProgressIndicator(currentSet: current, previousSet: previous)
        #expect(result == .up)
    }

    // MARK: - Same Weight, Reps Changed

    @Test("Same weight, more reps → up")
    func sameWeight_moreReps_isUp() {
        let current = makeSet(weight: 185, reps: 10)
        let previous = makeSet(weight: 185, reps: 8)

        let result = viewModel.getProgressIndicator(currentSet: current, previousSet: previous)
        #expect(result == .up)
    }

    @Test("Same weight, fewer reps → down")
    func sameWeight_fewerReps_isDown() {
        let current = makeSet(weight: 185, reps: 6)
        let previous = makeSet(weight: 185, reps: 8)

        let result = viewModel.getProgressIndicator(currentSet: current, previousSet: previous)
        #expect(result == .down)
    }

    @Test("Same weight, same reps → none")
    func sameWeight_sameReps_isNone() {
        let current = makeSet(weight: 185, reps: 8)
        let previous = makeSet(weight: 185, reps: 8)

        let result = viewModel.getProgressIndicator(currentSet: current, previousSet: previous)
        #expect(result == .none)
    }

    // MARK: - Weight Decreased

    @Test("Weight decreased at same reps → down")
    func weightDown_sameReps_isDown() {
        let current = makeSet(weight: 180, reps: 8)
        let previous = makeSet(weight: 185, reps: 8)

        let result = viewModel.getProgressIndicator(currentSet: current, previousSet: previous)
        #expect(result == .down)
    }

    @Test("Weight decreased with more reps → down")
    func weightDown_moreReps_isDown() {
        let current = makeSet(weight: 175, reps: 12)
        let previous = makeSet(weight: 185, reps: 8)

        let result = viewModel.getProgressIndicator(currentSet: current, previousSet: previous)
        #expect(result == .down)
    }

    // MARK: - No Previous Set

    @Test("No previous set → none")
    func noPreviousSet_isNone() {
        let current = makeSet(weight: 185, reps: 8)

        let result = viewModel.getProgressIndicator(currentSet: current, previousSet: nil)
        #expect(result == .none)
    }

    // MARK: - Nil Values

    @Test("Current weight is nil → none")
    func currentWeightNil_isNone() {
        let current = makeSet(weight: nil, reps: 8)
        let previous = makeSet(weight: 185, reps: 8)

        let result = viewModel.getProgressIndicator(currentSet: current, previousSet: previous)
        #expect(result == .none)
    }

    @Test("Current reps is nil → none")
    func currentRepsNil_isNone() {
        let current = makeSet(weight: 185, reps: nil)
        let previous = makeSet(weight: 185, reps: 8)

        let result = viewModel.getProgressIndicator(currentSet: current, previousSet: previous)
        #expect(result == .none)
    }

    @Test("Previous weight is nil → none")
    func previousWeightNil_isNone() {
        let current = makeSet(weight: 185, reps: 8)
        let previous = makeSet(weight: nil, reps: 8)

        let result = viewModel.getProgressIndicator(currentSet: current, previousSet: previous)
        #expect(result == .none)
    }

    @Test("Previous reps is nil → none")
    func previousRepsNil_isNone() {
        let current = makeSet(weight: 185, reps: 8)
        let previous = makeSet(weight: 185, reps: nil)

        let result = viewModel.getProgressIndicator(currentSet: current, previousSet: previous)
        #expect(result == .none)
    }

    @Test("Both sets have nil values → none")
    func bothNil_isNone() {
        let current = makeSet(weight: nil, reps: nil)
        let previous = makeSet(weight: nil, reps: nil)

        let result = viewModel.getProgressIndicator(currentSet: current, previousSet: previous)
        #expect(result == .none)
    }

    // MARK: - Edge Cases

    @Test("Minimal weight increase (0.5 lb) → up")
    func minimalWeightIncrease_isUp() {
        let current = makeSet(weight: 185.5, reps: 8)
        let previous = makeSet(weight: 185.0, reps: 8)

        let result = viewModel.getProgressIndicator(currentSet: current, previousSet: previous)
        #expect(result == .up)
    }

    @Test("One extra rep at same weight → up")
    func oneExtraRep_isUp() {
        let current = makeSet(weight: 185, reps: 9)
        let previous = makeSet(weight: 185, reps: 8)

        let result = viewModel.getProgressIndicator(currentSet: current, previousSet: previous)
        #expect(result == .up)
    }
}
