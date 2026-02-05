//
//  ActiveWorkoutViewModel.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import ActivityKit
import AudioToolbox
import Foundation
import Observation
import SwiftData
import SwiftUI

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

    // Recent exercises for home view
    var recentExercises: [Exercise] = []

    // Rest timer
    var restTimeRemaining: Int = 0
    var isRestTimerActive = false
    var isRestTimerPaused = false
    nonisolated(unsafe) private var restTimer: Timer?
    private var restTimerTotalDuration: Int = 0
    private var restTimerExerciseName: String = ""
    private var restTimerSetInfo: String = ""

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.workoutRepository = WorkoutRepository(modelContext: modelContext)
        self.exerciseRepository = ExerciseRepository(modelContext: modelContext)
    }

    // MARK: - Recent Exercises

    func loadRecentExercises() {
        recentExercises = workoutRepository.fetchRecentExercises()
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
        stopRestTimer()
        currentWorkout = nil
        elapsedTime = 0
    }

    func cancelWorkout() {
        guard let workout = currentWorkout else { return }
        workoutRepository.deleteWorkout(workout)
        stopTimer()
        stopRestTimer()
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

    func addExerciseFromPastWorkout(_ pastWorkoutExercise: WorkoutExercise) {
        guard let workout = currentWorkout,
              let exercise = pastWorkoutExercise.exercise else { return }
        let workoutExercise = workoutRepository.addExerciseToWorkout(workout, exercise: exercise)

        let pastSets = pastWorkoutExercise.completedSets.sorted { $0.setNumber < $1.setNumber }
        if pastSets.isEmpty {
            addSet(to: workoutExercise, weight: nil, reps: nil)
        } else {
            for pastSet in pastSets {
                addSet(to: workoutExercise, weight: pastSet.weight, reps: pastSet.reps)
            }
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

    func updateSetRPE(_ set: ExerciseSet, rpe: Int?) {
        set.rpe = rpe
        workoutRepository.save()
    }

    func completeSet(_ set: ExerciseSet) {
        set.completedAt = Date()

        // Check if this is a personal record
        checkAndSetPersonalRecord(set)

        workoutRepository.save()

        // Capture exercise context for Live Activity
        let exerciseName = set.workoutExercise?.exercise?.name ?? "Rest"
        let setNumber = set.setNumber
        let setType = set.setType.displayName

        // Start rest timer with duration based on set type
        let duration = restDurationForSetType(set.setType)
        startRestTimer(duration: duration, exerciseName: exerciseName, setInfo: "Set \(setNumber) · \(setType)")
    }

    private func restDurationForSetType(_ setType: ExerciseSet.SetType) -> Int {
        switch setType {
        case .warmup:
            return 60  // 1 minute for warmup sets
        case .working:
            return 120 // 2 minutes for heavy working sets
        case .dropSet:
            return 60  // 1 minute for drop sets
        case .toFailure:
            return 90  // 1.5 minutes for sets to failure
        }
    }

    private func checkAndSetPersonalRecord(_ set: ExerciseSet) {
        guard let workoutExercise = set.workoutExercise,
              let exercise = workoutExercise.exercise,
              let currentWeight = set.weight,
              let currentReps = set.reps,
              currentReps > 0 else {
            return
        }

        // Get all previous completed sets for this exercise (excluding current workout)
        guard let currentWorkout = currentWorkout else { return }

        var allPreviousSets: [ExerciseSet] = []
        for workout in workoutRepository.fetchAllWorkouts() {
            // Skip current workout
            if workout.id == currentWorkout.id { continue }

            for we in workout.exercises {
                if we.exercise?.id == exercise.id {
                    allPreviousSets.append(contentsOf: we.completedSets)
                }
            }
        }

        // If no previous sets, this is a PR
        if allPreviousSets.isEmpty {
            set.isPersonalRecord = true
            return
        }

        // Calculate estimated 1RM for current set using Brzycki formula
        let current1RM = currentWeight * (36.0 / (37.0 - Double(currentReps)))

        // Check if this beats any previous set
        var isPR = true
        for previousSet in allPreviousSets {
            guard let prevWeight = previousSet.weight,
                  let prevReps = previousSet.reps,
                  prevReps > 0 else { continue }

            let prev1RM = prevWeight * (36.0 / (37.0 - Double(prevReps)))

            // If previous 1RM is higher or equal, this is not a PR
            if prev1RM >= current1RM {
                isPR = false
                break
            }
        }

        set.isPersonalRecord = isPR
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

    func startRestTimer(duration: Int, exerciseName: String = "Rest", setInfo: String = "") {
        stopRestTimer()
        restTimeRemaining = duration
        restTimerTotalDuration = duration
        restTimerExerciseName = exerciseName
        restTimerSetInfo = setInfo
        isRestTimerActive = true

        // Start Live Activity
        LiveActivityManager.shared.startRestTimerActivity(
            exerciseName: exerciseName,
            setInfo: setInfo,
            totalDuration: duration
        )

        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if !self.isRestTimerPaused {
                    if self.restTimeRemaining > 0 {
                        self.restTimeRemaining -= 1
                        LiveActivityManager.shared.updateRestTimer(
                            remainingSeconds: self.restTimeRemaining,
                            isPaused: false
                        )
                    } else {
                        self.restTimerCompleted()
                    }
                }
            }
        }
    }

    func stopRestTimer() {
        isRestTimerActive = false
        isRestTimerPaused = false
        restTimer?.invalidate()
        restTimer = nil
        restTimeRemaining = 0
        restTimerTotalDuration = 0

        // End Live Activity
        LiveActivityManager.shared.endRestTimerActivity()
    }

    func skipRestTimer() {
        stopRestTimer()
    }

    func pauseRestTimer() {
        isRestTimerPaused = true
        LiveActivityManager.shared.updateRestTimer(
            remainingSeconds: restTimeRemaining,
            isPaused: true
        )
    }

    func resumeRestTimer() {
        isRestTimerPaused = false
        LiveActivityManager.shared.updateRestTimer(
            remainingSeconds: restTimeRemaining,
            isPaused: false
        )
    }

    func addRestTime(_ seconds: Int) {
        restTimeRemaining += seconds
        restTimerTotalDuration += seconds
        if !isRestTimerActive {
            startRestTimer(duration: restTimeRemaining, exerciseName: restTimerExerciseName, setInfo: restTimerSetInfo)
        } else {
            // Update existing Live Activity with new remaining time
            LiveActivityManager.shared.updateRestTimer(
                remainingSeconds: restTimeRemaining,
                isPaused: isRestTimerPaused
            )
        }
    }

    private func restTimerCompleted() {
        // Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // Play system sound (tri-tone)
        AudioServicesPlaySystemSound(1005)

        stopRestTimer()
    }

    // MARK: - Workout Stats

    var totalVolume: Double {
        guard let workout = currentWorkout else { return 0 }

        var volume: Double = 0
        for workoutExercise in workout.exercises {
            for set in workoutExercise.sets where set.isCompleted {
                if let weight = set.weight, let reps = set.reps {
                    volume += weight * Double(reps)
                }
            }
        }
        return volume
    }

    var totalSetsCompleted: Int {
        guard let workout = currentWorkout else { return 0 }

        var count = 0
        for workoutExercise in workout.exercises {
            count += workoutExercise.sets.filter { $0.isCompleted }.count
        }
        return count
    }

    // MARK: - Cleanup

    deinit {
        timer?.invalidate()
        restTimer?.invalidate()
        // Note: LiveActivityManager.endRestTimerActivity() called from stopRestTimer()
        // deinit cannot call @MainActor methods directly
    }
}

// MARK: - Supporting Types

enum ProgressIndicator {
    case up
    case down
    case none
}
