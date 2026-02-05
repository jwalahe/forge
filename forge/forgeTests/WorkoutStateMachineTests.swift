//
//  WorkoutStateMachineTests.swift
//  forgeTests
//
//  Tests workout lifecycle: start → finish/cancel transitions.
//  A broken state machine means lost workouts — catastrophic for trust.
//

import Testing
import Foundation
import SwiftData
@testable import forge

@MainActor
@Suite("Workout State Machine Tests")
struct WorkoutStateMachineTests {
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

    private func fetchCount<T: PersistentModel>(_ type: T.Type) -> Int {
        let descriptor = FetchDescriptor<T>()
        return (try? context.fetchCount(descriptor)) ?? -1
    }

    // MARK: - Start Workout

    @Test("Starting a new workout sets currentWorkout")
    func startNewWorkout_setsCurrentWorkout() {
        #expect(viewModel.currentWorkout == nil)

        viewModel.startNewWorkout()

        #expect(viewModel.currentWorkout != nil)
    }

    @Test("New workout has no endTime (in progress)")
    func startNewWorkout_endTimeIsNil() {
        viewModel.startNewWorkout()

        #expect(viewModel.currentWorkout?.endTime == nil)
        #expect(viewModel.currentWorkout?.isInProgress == true)
    }

    @Test("New workout is persisted in SwiftData")
    func startNewWorkout_persistedInContext() {
        viewModel.startNewWorkout()

        let count = fetchCount(Workout.self)
        #expect(count == 1)
    }

    @Test("New workout starts the elapsed timer")
    func startNewWorkout_startsTimer() {
        viewModel.startNewWorkout()

        #expect(viewModel.isTimerRunning == true)
    }

    @Test("Starting workout sets startTime to approximately now")
    func startNewWorkout_setsStartTime() {
        let beforeStart = Date()
        viewModel.startNewWorkout()
        let afterStart = Date()

        guard let startTime = viewModel.currentWorkout?.startTime else {
            Issue.record("No start time")
            return
        }

        #expect(startTime >= beforeStart)
        #expect(startTime <= afterStart)
    }

    // MARK: - Finish Workout

    @Test("Finishing a workout sets endTime")
    func finishWorkout_setsEndTime() {
        viewModel.startNewWorkout()
        let workout = viewModel.currentWorkout!

        viewModel.finishWorkout()

        #expect(workout.endTime != nil)
    }

    @Test("Finishing a workout clears currentWorkout")
    func finishWorkout_clearsCurrentWorkout() {
        viewModel.startNewWorkout()

        viewModel.finishWorkout()

        #expect(viewModel.currentWorkout == nil)
    }

    @Test("Finishing a workout stops the timer")
    func finishWorkout_stopsTimer() {
        viewModel.startNewWorkout()

        viewModel.finishWorkout()

        #expect(viewModel.isTimerRunning == false)
    }

    @Test("Finishing a workout resets elapsed time")
    func finishWorkout_resetsElapsedTime() {
        viewModel.startNewWorkout()
        viewModel.elapsedTime = 120 // Simulate 2 minutes

        viewModel.finishWorkout()

        #expect(viewModel.elapsedTime == 0)
    }

    @Test("Finished workout is NOT in progress")
    func finishWorkout_isNoLongerInProgress() {
        viewModel.startNewWorkout()
        let workout = viewModel.currentWorkout!

        viewModel.finishWorkout()

        #expect(workout.isInProgress == false)
    }

    @Test("Finished workout persists in database (not deleted)")
    func finishWorkout_persistsWorkout() {
        viewModel.startNewWorkout()

        viewModel.finishWorkout()

        let count = fetchCount(Workout.self)
        #expect(count == 1)
    }

    // MARK: - Cancel Workout

    @Test("Cancelling a workout deletes it from database")
    func cancelWorkout_deletesWorkout() {
        viewModel.startNewWorkout()

        viewModel.cancelWorkout()

        let count = fetchCount(Workout.self)
        #expect(count == 0)
    }

    @Test("Cancelling a workout clears currentWorkout")
    func cancelWorkout_clearsCurrentWorkout() {
        viewModel.startNewWorkout()

        viewModel.cancelWorkout()

        #expect(viewModel.currentWorkout == nil)
    }

    @Test("Cancelling a workout stops the timer")
    func cancelWorkout_stopsTimer() {
        viewModel.startNewWorkout()

        viewModel.cancelWorkout()

        #expect(viewModel.isTimerRunning == false)
    }

    @Test("Cancelling a workout resets elapsed time")
    func cancelWorkout_resetsElapsedTime() {
        viewModel.startNewWorkout()
        viewModel.elapsedTime = 300

        viewModel.cancelWorkout()

        #expect(viewModel.elapsedTime == 0)
    }

    @Test("Cancelling a workout with exercises cascades delete")
    func cancelWorkout_cascadesDelete() {
        let benchPress = createExercise()
        viewModel.startNewWorkout()
        viewModel.addExercise(benchPress)

        viewModel.cancelWorkout()

        let workoutCount = fetchCount(Workout.self)
        let workoutExerciseCount = fetchCount(WorkoutExercise.self)
        #expect(workoutCount == 0)
        #expect(workoutExerciseCount == 0)
    }

    // MARK: - Load In-Progress Workout

    @Test("loadInProgressWorkout restores existing workout")
    func loadInProgressWorkout_restoresWorkout() {
        // Create an in-progress workout directly
        let workout = Workout(startTime: Date().addingTimeInterval(-600)) // 10 min ago
        context.insert(workout)
        try? context.save()

        viewModel.loadInProgressWorkout()

        #expect(viewModel.currentWorkout != nil)
        #expect(viewModel.currentWorkout?.id == workout.id)
    }

    @Test("loadInProgressWorkout sets elapsed time from startTime")
    func loadInProgressWorkout_setsElapsedTime() {
        let tenMinAgo = Date().addingTimeInterval(-600)
        let workout = Workout(startTime: tenMinAgo)
        context.insert(workout)
        try? context.save()

        viewModel.loadInProgressWorkout()

        // Elapsed time should be approximately 600 seconds
        #expect(viewModel.elapsedTime >= 599)
        #expect(viewModel.elapsedTime <= 602)
    }

    @Test("loadInProgressWorkout does nothing when no workout in progress")
    func loadInProgressWorkout_noWorkoutInProgress() {
        // Create a finished workout
        let workout = Workout(endTime: Date())
        context.insert(workout)
        try? context.save()

        viewModel.loadInProgressWorkout()

        #expect(viewModel.currentWorkout == nil)
    }

    // MARK: - Rest Timer Durations

    @Test("Warmup set starts 60s rest timer")
    func restTimer_warmup_60seconds() {
        viewModel.startNewWorkout()
        let benchPress = createExercise()
        viewModel.addExercise(benchPress)

        guard let workoutExercise = viewModel.currentWorkout?.exercises.first,
              let set = workoutExercise.sets.first else {
            Issue.record("No set found")
            return
        }

        viewModel.updateSet(set, weight: 95, reps: 10)
        viewModel.updateSetType(set, type: .warmup)
        viewModel.completeSet(set)

        #expect(viewModel.isRestTimerActive == true)
        #expect(viewModel.restTimeRemaining == 60)
    }

    @Test("Working set starts 120s rest timer")
    func restTimer_working_120seconds() {
        viewModel.startNewWorkout()
        let benchPress = createExercise()
        viewModel.addExercise(benchPress)

        guard let workoutExercise = viewModel.currentWorkout?.exercises.first,
              let set = workoutExercise.sets.first else {
            Issue.record("No set found")
            return
        }

        viewModel.updateSet(set, weight: 185, reps: 8)
        // Default type is .working
        viewModel.completeSet(set)

        #expect(viewModel.isRestTimerActive == true)
        #expect(viewModel.restTimeRemaining == 120)
    }

    @Test("Drop set starts 60s rest timer")
    func restTimer_dropSet_60seconds() {
        viewModel.startNewWorkout()
        let benchPress = createExercise()
        viewModel.addExercise(benchPress)

        guard let workoutExercise = viewModel.currentWorkout?.exercises.first,
              let set = workoutExercise.sets.first else {
            Issue.record("No set found")
            return
        }

        viewModel.updateSet(set, weight: 135, reps: 12)
        viewModel.updateSetType(set, type: .dropSet)
        viewModel.completeSet(set)

        #expect(viewModel.isRestTimerActive == true)
        #expect(viewModel.restTimeRemaining == 60)
    }

    @Test("To-failure set starts 90s rest timer")
    func restTimer_toFailure_90seconds() {
        viewModel.startNewWorkout()
        let benchPress = createExercise()
        viewModel.addExercise(benchPress)

        guard let workoutExercise = viewModel.currentWorkout?.exercises.first,
              let set = workoutExercise.sets.first else {
            Issue.record("No set found")
            return
        }

        viewModel.updateSet(set, weight: 185, reps: 6)
        viewModel.updateSetType(set, type: .toFailure)
        viewModel.completeSet(set)

        #expect(viewModel.isRestTimerActive == true)
        #expect(viewModel.restTimeRemaining == 90)
    }

    // MARK: - Edge: Finish/Cancel with No Workout

    @Test("Finishing with no active workout does nothing")
    func finishWorkout_noActiveWorkout_doesNothing() {
        #expect(viewModel.currentWorkout == nil)

        viewModel.finishWorkout() // Should not crash

        #expect(viewModel.currentWorkout == nil)
    }

    @Test("Cancelling with no active workout does nothing")
    func cancelWorkout_noActiveWorkout_doesNothing() {
        #expect(viewModel.currentWorkout == nil)

        viewModel.cancelWorkout() // Should not crash

        #expect(viewModel.currentWorkout == nil)
    }
}
