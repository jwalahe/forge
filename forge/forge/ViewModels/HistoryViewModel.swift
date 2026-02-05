//
//  HistoryViewModel.swift
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
class HistoryViewModel {
    private let workoutRepository: WorkoutRepository
    private let modelContext: ModelContext

    var workouts: [Workout] = []
    var selectedMonth: Date = Date()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.workoutRepository = WorkoutRepository(modelContext: modelContext)
        loadWorkouts()
    }

    // MARK: - Data Loading

    func loadWorkouts() {
        workouts = workoutRepository.fetchAllWorkouts()
    }

    func workoutsForMonth(_ date: Date) -> [Workout] {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return []
        }

        return workoutRepository.fetchWorkouts(from: monthStart, to: monthEnd)
    }

    func workoutsGroupedByDate() -> [Date: [Workout]] {
        let calendar = Calendar.current
        var grouped: [Date: [Workout]] = [:]

        for workout in workouts {
            let startOfDay = calendar.startOfDay(for: workout.startTime)
            if grouped[startOfDay] == nil {
                grouped[startOfDay] = []
            }
            grouped[startOfDay]?.append(workout)
        }

        return grouped
    }

    // MARK: - Calendar Helpers

    func hasWorkout(on date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        return workouts.contains { workout in
            let workoutStartOfDay = calendar.startOfDay(for: workout.startTime)
            return workoutStartOfDay == startOfDay
        }
    }

    func workouts(on date: Date) -> [Workout] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        return workouts.filter { workout in
            let workoutStartOfDay = calendar.startOfDay(for: workout.startTime)
            return workoutStartOfDay == startOfDay
        }
    }

    // MARK: - Actions

    func deleteWorkout(_ workout: Workout) {
        workoutRepository.deleteWorkout(workout)
        loadWorkouts()
    }

    func repeatWorkout(_ workout: Workout, activeWorkoutViewModel: ActiveWorkoutViewModel) {
        activeWorkoutViewModel.startNewWorkout()

        // Add all exercises with their previous weights/reps pre-filled
        for workoutExercise in workout.exercises.sorted(by: { $0.order < $1.order }) {
            activeWorkoutViewModel.addExerciseFromPastWorkout(workoutExercise)
        }
    }

    // MARK: - Export

    func generateCSVFileURL() -> URL? {
        let csv = workoutRepository.generateCSV()
        let fileName = "forge_workouts_\(Date().formatted("yyyy-MM-dd")).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            return nil
        }
    }

    // MARK: - Stats

    func totalWorkouts() -> Int {
        workouts.count
    }

    func totalVolume() -> Double {
        workouts.reduce(0) { $0 + $1.totalVolume }
    }

    func totalPersonalRecords() -> Int {
        workouts.reduce(0) { $0 + $1.personalRecordsCount }
    }

    func currentStreak() -> Int {
        guard !workouts.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedWorkouts = workouts.sorted { $0.startTime > $1.startTime }
        let today = calendar.startOfDay(for: Date())

        var streak = 0
        var currentDate = today

        // Check if there's a workout today or yesterday to start the streak
        let hasRecentWorkout = sortedWorkouts.contains { workout in
            let workoutDay = calendar.startOfDay(for: workout.startTime)
            return workoutDay == today || workoutDay == calendar.date(byAdding: .day, value: -1, to: today)
        }

        guard hasRecentWorkout else { return 0 }

        // Count consecutive days with workouts
        var workoutDays = Set(sortedWorkouts.map { calendar.startOfDay(for: $0.startTime) })

        while workoutDays.contains(currentDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDay
        }

        return streak
    }
}
