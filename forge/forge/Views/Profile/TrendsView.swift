//
//  TrendsView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI
import SwiftData
import Charts

struct TrendsView: View {
    let viewModel: HistoryViewModel
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedExercise: Exercise?
    @State private var showingExercisePicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Time range picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    Text("Week").tag(TimeRange.week)
                    Text("Month").tag(TimeRange.month)
                    Text("3 Months").tag(TimeRange.threeMonths)
                    Text("Year").tag(TimeRange.year)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Workout frequency chart
                workoutFrequencySection

                // Personal Records chart
                personalRecordsSection

                // Workout duration trends
                durationTrendsSection

                // Exercise-specific analytics
                exerciseAnalyticsSection
            }
            .padding(.vertical)
        }
        .navigationTitle("Trends & Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var workoutFrequencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workout Frequency")
                .font(.headline)
                .padding(.horizontal)

            if !filteredWorkouts.isEmpty {
                Chart {
                    ForEach(workoutsByWeek, id: \.week) { data in
                        BarMark(
                            x: .value("Week", data.week, unit: .weekOfYear),
                            y: .value("Workouts", data.count)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.forgeAccent, Color.forgeAccent.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(4)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.week())
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)
            } else {
                emptyChartState(message: "No workouts in this time range")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Records")
                .font(.headline)
                .padding(.horizontal)

            if !filteredWorkouts.isEmpty && filteredWorkouts.contains(where: { $0.personalRecordsCount > 0 }) {
                Chart {
                    ForEach(workoutsWithPRs, id: \.date) { data in
                        LineMark(
                            x: .value("Date", data.date),
                            y: .value("PRs", data.prCount)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.orange, Color.yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .symbol(.circle)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", data.date),
                            y: .value("PRs", data.prCount)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: selectedTimeRange == .week ? 1 : 7)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)
            } else {
                emptyChartState(message: "No personal records in this time range")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var durationTrendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workout Duration")
                .font(.headline)
                .padding(.horizontal)

            if !filteredWorkouts.isEmpty {
                Chart {
                    ForEach(workoutsWithDuration, id: \.date) { data in
                        LineMark(
                            x: .value("Date", data.date),
                            y: .value("Minutes", data.durationMinutes)
                        )
                        .foregroundStyle(Color.blue)
                        .symbol(.circle)

                        PointMark(
                            x: .value("Date", data.date),
                            y: .value("Minutes", data.durationMinutes)
                        )
                        .foregroundStyle(Color.blue)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let minutes = value.as(Double.self) {
                                Text("\(Int(minutes)) min")
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: selectedTimeRange == .week ? 1 : 7)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)
            } else {
                emptyChartState(message: "No workout duration data")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var exerciseAnalyticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Exercise Progress")
                    .font(.headline)

                Spacer()

                Button {
                    showingExercisePicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedExercise?.name ?? "Select Exercise")
                            .font(.subheadline)
                            .foregroundColor(.forgeAccent)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.forgeAccent)
                    }
                }
            }
            .padding(.horizontal)

            if let exercise = selectedExercise {
                exerciseProgressChart(for: exercise)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Select an exercise to view progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
        .sheet(isPresented: $showingExercisePicker) {
            exercisePickerSheet
        }
    }

    private func exerciseProgressChart(for exercise: Exercise) -> some View {
        let exerciseSets = getExerciseSets(for: exercise)

        return Group {
            if !exerciseSets.isEmpty {
                Chart {
                    ForEach(exerciseSets, id: \.date) { data in
                        LineMark(
                            x: .value("Date", data.date),
                            y: .value("Weight", data.maxWeight)
                        )
                        .foregroundStyle(Color.forgeAccent)
                        .symbol(.circle)

                        PointMark(
                            x: .value("Date", data.date),
                            y: .value("Weight", data.maxWeight)
                        )
                        .foregroundStyle(Color.forgeAccent)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let weight = value.as(Double.self) {
                                Text("\(Int(weight)) lbs")
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: selectedTimeRange == .week ? 1 : 7)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)
            } else {
                emptyChartState(message: "No data for this exercise")
            }
        }
    }

    private var exercisePickerSheet: some View {
        NavigationStack {
            List {
                ForEach(uniqueExercises, id: \.id) { exercise in
                    Button {
                        selectedExercise = exercise
                        showingExercisePicker = false
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .foregroundColor(.primary)
                                Text(exercise.muscleGroup.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedExercise?.id == exercise.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.forgeAccent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingExercisePicker = false
                    }
                }
            }
        }
    }

    private func emptyChartState(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed Properties

    private var filteredWorkouts: [Workout] {
        let calendar = Calendar.current
        let now = Date()

        let startDate: Date
        switch selectedTimeRange {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)!
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: now)!
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now)!
        }

        return viewModel.workouts.filter { $0.startTime >= startDate }
    }

    private var workoutsByWeek: [(week: Date, count: Int)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredWorkouts) { workout in
            calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.startTime))!
        }

        return grouped.map { (week: $0.key, count: $0.value.count) }
            .sorted { $0.week < $1.week }
    }

    private var workoutsWithPRs: [(date: Date, prCount: Int)] {
        filteredWorkouts
            .filter { $0.personalRecordsCount > 0 }
            .map { (date: $0.startTime, prCount: $0.personalRecordsCount) }
            .sorted { $0.date < $1.date }
    }

    private var workoutsWithDuration: [(date: Date, durationMinutes: Double)] {
        filteredWorkouts
            .compactMap { workout -> (date: Date, durationMinutes: Double)? in
                guard let duration = workout.duration else { return nil }
                return (date: workout.startTime, durationMinutes: duration / 60.0)
            }
            .sorted { $0.date < $1.date }
    }

    private var uniqueExercises: [Exercise] {
        var seen = Set<UUID>()
        var exercises: [Exercise] = []

        for workout in viewModel.workouts {
            for workoutExercise in workout.exercises {
                if let exercise = workoutExercise.exercise, !seen.contains(exercise.id) {
                    seen.insert(exercise.id)
                    exercises.append(exercise)
                }
            }
        }

        return exercises.sorted { $0.name < $1.name }
    }

    private func getExerciseSets(for exercise: Exercise) -> [(date: Date, maxWeight: Double)] {
        var results: [(date: Date, maxWeight: Double)] = []

        for workout in filteredWorkouts {
            for workoutExercise in workout.exercises {
                if workoutExercise.exercise?.id == exercise.id {
                    let maxWeight = workoutExercise.completedSets
                        .compactMap { $0.weight }
                        .max() ?? 0
                    if maxWeight > 0 {
                        results.append((date: workout.startTime, maxWeight: maxWeight))
                    }
                }
            }
        }

        return results.sorted { $0.date < $1.date }
    }

    // MARK: - Supporting Types

    enum TimeRange {
        case week
        case month
        case threeMonths
        case year
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workout.self, configurations: config)
    let context = container.mainContext

    let exercise = Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell)
    let workout = Workout(startTime: Date().addingTimeInterval(-86400), endTime: Date().addingTimeInterval(-82800))
    let we = WorkoutExercise(workout: workout, exercise: exercise, order: 0)
    let set = ExerciseSet(workoutExercise: we, setNumber: 1, weight: 185, reps: 8, completedAt: Date())

    context.insert(exercise)
    context.insert(workout)
    context.insert(we)
    context.insert(set)

    we.sets = [set]
    workout.exercises = [we]

    let viewModel = HistoryViewModel(modelContext: context)

    return NavigationStack {
        TrendsView(viewModel: viewModel)
    }
    .modelContainer(container)
}
