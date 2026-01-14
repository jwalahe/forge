//
//  ActiveWorkoutViewModel.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import Foundation
import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
class ActiveWorkoutViewModel {
    private let workoutRepository: WorkoutRepository
    private let exerciseRepository: ExerciseRepository
    private let modelContext: ModelContext

    var currentWorkout: Workout?
    var elapsedTime: TimeInterval = 0
    var isTimerRunning = false
    nonisolated(unsafe) private var timer: Timer?

    // Rest timer
    var restTimeRemaining: Int = 0
    var isRestTimerActive = false
    nonisolated(unsafe) private var restTimer: Timer?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.workoutRepository = WorkoutRepository(modelContext: modelContext)
        self.exerciseRepository = ExerciseRepository(modelContext: modelContext)
    }

    // MARK: - Workout Management

    func startNewWorkout() {
        currentWorkout = workoutRepository.createWorkout()
        startTimer()
    }

    func loadInProgressWorkout() {
        if let workout = workoutRepository.fetchInProgressWorkout() {
            currentWorkout = workout
            elapsedTime = Date().timeIntervalSince(workout.startTime)
            startTimer()
        }
    }

    func finishWorkout() {
        guard let workout = currentWorkout else { return }
        workoutRepository.finishWorkout(workout)
        stopTimer()
        currentWorkout = nil
        elapsedTime = 0
    }

    func cancelWorkout() {
        guard let workout = currentWorkout else { return }
        workoutRepository.deleteWorkout(workout)
        stopTimer()
        currentWorkout = nil
        elapsedTime = 0
    }

    // MARK: - Exercise Management

    func addExercise(_ exercise: Exercise) {
        guard let workout = currentWorkout else { return }
        let workoutExercise = workoutRepository.addExerciseToWorkout(workout, exercise: exercise)

        // Get previous performance and auto-create first set
        if let previousWorkoutExercise = getPreviousWorkoutExercise(for: exercise) {
            if let firstSet = previousWorkoutExercise.completedSets.first {
                addSet(to: workoutExercise, weight: firstSet.weight, reps: firstSet.reps)
            }
        } else {
            // No previous data, add empty set
            addSet(to: workoutExercise, weight: nil, reps: nil)
        }
    }

    func removeExercise(_ workoutExercise: WorkoutExercise) {
        workoutRepository.deleteWorkoutExercise(workoutExercise)
    }

    func reorderExercises(from source: IndexSet, to destination: Int) {
        guard let workout = currentWorkout else { return }
        var exercises = workout.exercises.sorted { $0.order < $1.order }
        exercises.move(fromOffsets: source, toOffset: destination)

        for (index, exercise) in exercises.enumerated() {
            exercise.order = index
        }
        workoutRepository.save()
    }

    // MARK: - Set Management

    func addSet(to workoutExercise: WorkoutExercise, weight: Double? = nil, reps: Int? = nil) {
        let setNumber = workoutExercise.sets.count + 1
        let set = ExerciseSet(
            workoutExercise: workoutExercise,
            setNumber: setNumber,
            weight: weight,
            reps: reps
        )
        modelContext.insert(set)
        workoutExercise.sets.append(set)
        workoutRepository.save()
    }

    func updateSet(_ set: ExerciseSet, weight: Double?, reps: Int?) {
        set.weight = weight
        set.reps = reps
        workoutRepository.save()
    }

    func updateSetType(_ set: ExerciseSet, type: ExerciseSet.SetType) {
        set.setType = type
        workoutRepository.save()
    }

    func completeSet(_ set: ExerciseSet) {
        set.completedAt = Date()
        workoutRepository.save()

        // Start rest timer (90 seconds default)
        startRestTimer(duration: 90)
    }

    func deleteSet(_ set: ExerciseSet) {
        guard let workoutExercise = set.workoutExercise else { return }
        modelContext.delete(set)

        // Renumber remaining sets
        let remainingSets = workoutExercise.sets.sorted { $0.setNumber < $1.setNumber }
        for (index, remainingSet) in remainingSets.enumerated() {
            remainingSet.setNumber = index + 1
        }
        workoutRepository.save()
    }

    func updateExerciseNotes(_ workoutExercise: WorkoutExercise, notes: String) {
        workoutExercise.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        workoutRepository.save()
    }

    // MARK: - Previous Performance

    func getPreviousWorkoutExercise(for exercise: Exercise) -> WorkoutExercise? {
        guard let workout = currentWorkout else { return nil }
        return workoutRepository.getPreviousWorkoutExercise(for: exercise, before: workout.startTime)
    }

    func getProgressIndicator(currentSet: ExerciseSet, previousSet: ExerciseSet?) -> ProgressIndicator {
        guard let previousSet = previousSet else {
            return .none
        }

        guard let currentWeight = currentSet.weight,
              let currentReps = currentSet.reps,
              let previousWeight = previousSet.weight,
              let previousReps = previousSet.reps else {
            return .none
        }

        // Compare: if weight increased OR (weight same AND reps increased) = up
        if currentWeight > previousWeight {
            return .up
        } else if currentWeight == previousWeight && currentReps > previousReps {
            return .up
        } else if currentWeight < previousWeight || (currentWeight == previousWeight && currentReps < previousReps) {
            return .down
        }

        return .none
    }

    // MARK: - Timer

    private func startTimer() {
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedTime += 1
            }
        }
    }

    private func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Rest Timer

    func startRestTimer(duration: Int) {
        stopRestTimer()
        restTimeRemaining = duration
        isRestTimerActive = true

        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.restTimeRemaining > 0 {
                    self.restTimeRemaining -= 1
                } else {
                    self.stopRestTimer()
                }
            }
        }
    }

    func stopRestTimer() {
        isRestTimerActive = false
        restTimer?.invalidate()
        restTimer = nil
        restTimeRemaining = 0
    }

    func skipRestTimer() {
        stopRestTimer()
    }

    // MARK: - Cleanup

    deinit {
        timer?.invalidate()
        restTimer?.invalidate()
    }
}

// MARK: - Supporting Types

enum ProgressIndicator {
    case up
    case down
    case none
}
