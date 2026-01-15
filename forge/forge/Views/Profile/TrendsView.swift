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
    @State private var selectedTab: AnalyticsTab = .overview
    @State private var selectedExercise: Exercise?
    @State private var showingExercisePicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("Analytics Tab", selection: $selectedTab) {
                Text("Overview").tag(AnalyticsTab.overview)
                Text("Exercise").tag(AnalyticsTab.exercise)
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollView {
                VStack(spacing: 20) {
                    if selectedTab == .overview {
                        overviewContent
                    } else {
                        exerciseContent
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingExercisePicker) {
            exercisePickerSheet
        }
    }

    // MARK: - Overview Tab

    private var overviewContent: some View {
        VStack(spacing: 20) {
            // Key stats cards
            statsOverview

            // Volume progression chart
            volumeProgressionSection

            // Workout consistency
            consistencySection

            // Recent PRs list
            recentPRsSection
        }
    }

    private var statsOverview: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            QuickStatCard(
                title: "Total Volume",
                value: formatVolume(totalVolume),
                subtitle: "Last 30 days",
                color: .blue,
                icon: "scalemass.fill"
            )

            QuickStatCard(
                title: "Avg / Week",
                value: "\(workoutsPerWeek)",
                subtitle: "workouts/week",
                color: .green,
                icon: "calendar"
            )

            QuickStatCard(
                title: "Total PRs",
                value: "\(totalPRs)",
                subtitle: "All time",
                color: .orange,
                icon: "trophy.fill"
            )

            QuickStatCard(
                title: "Current Streak",
                value: "\(viewModel.currentStreak())",
                subtitle: "days",
                color: .red,
                icon: "flame.fill"
            )
        }
        .padding(.horizontal)
    }

    private var volumeProgressionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Volume Progression")
                        .font(.headline)
                    Text("Weekly total volume (weight × reps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)

            if !volumeByWeek.isEmpty {
                Chart {
                    ForEach(volumeByWeek, id: \.week) { data in
                        BarMark(
                            x: .value("Week", data.week, unit: .weekOfYear),
                            y: .value("Volume", data.volume)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(4)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let volume = value.as(Double.self) {
                                Text(formatVolume(volume))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .frame(height: 220)
                .padding(.horizontal)
            } else {
                emptyState("Start tracking workouts to see volume trends")
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var consistencySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout Consistency")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 16) {
                ConsistencyMetric(
                    title: "This Week",
                    value: "\(workoutsThisWeek)",
                    icon: "calendar.badge.clock",
                    color: .green
                )

                ConsistencyMetric(
                    title: "Avg Duration",
                    value: avgDuration,
                    icon: "timer",
                    color: .orange
                )

                ConsistencyMetric(
                    title: "Rest Days",
                    value: "\(avgRestDays)",
                    icon: "bed.double.fill",
                    color: .purple
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var recentPRsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Personal Records")
                .font(.headline)
                .padding(.horizontal)

            if !recentPRs.isEmpty {
                VStack(spacing: 8) {
                    ForEach(recentPRs.prefix(5), id: \.id) { pr in
                        PRRowView(pr: pr)
                    }
                }
                .padding(.horizontal)
            } else {
                emptyState("No personal records yet - keep pushing!")
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    // MARK: - Exercise Tab

    private var exerciseContent: some View {
        VStack(spacing: 20) {
            // Exercise picker
            Button {
                showingExercisePicker = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedExercise?.name ?? "Select an Exercise")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        if let exercise = selectedExercise {
                            Text(exercise.muscleGroup.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal)

            if let exercise = selectedExercise {
                exerciseDetailsView(for: exercise)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary.opacity(0.3))
                        .padding(.top, 40)

                    Text("Select an exercise to view detailed progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
        }
    }

    private func exerciseDetailsView(for exercise: Exercise) -> some View {
        VStack(spacing: 20) {
            // Exercise stats
            exerciseStatsGrid(for: exercise)

            // Weight progression chart
            weightProgressionChart(for: exercise)

            // Volume progression chart
            volumeChart(for: exercise)

            // Best sets
            bestSetsSection(for: exercise)
        }
    }

    private func exerciseStatsGrid(for exercise: Exercise) -> some View {
        let stats = getExerciseStats(for: exercise)

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            QuickStatCard(
                title: "Estimated 1RM",
                value: stats.estimated1RM > 0 ? "\(Int(stats.estimated1RM)) lbs" : "-",
                subtitle: "Brzycki formula",
                color: .purple,
                icon: "trophy.fill"
            )

            QuickStatCard(
                title: "Total Volume",
                value: formatVolume(stats.totalVolume),
                subtitle: "All time",
                color: .blue,
                icon: "scalemass.fill"
            )

            QuickStatCard(
                title: "Total Sets",
                value: "\(stats.totalSets)",
                subtitle: "All time",
                color: .green,
                icon: "list.bullet"
            )

            QuickStatCard(
                title: "Times Performed",
                value: "\(stats.workoutCount)",
                subtitle: "workouts",
                color: .orange,
                icon: "calendar"
            )
        }
        .padding(.horizontal)
    }

    private func weightProgressionChart(for exercise: Exercise) -> some View {
        let data = getWeightProgression(for: exercise)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Max Weight Progress")
                        .font(.headline)
                    Text("Heaviest weight lifted per session")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)

            if !data.isEmpty {
                Chart {
                    ForEach(data, id: \.date) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weight)
                        )
                        .foregroundStyle(Color.forgeAccent)
                        .lineStyle(StrokeStyle(lineWidth: 3))

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weight)
                        )
                        .foregroundStyle(Color.forgeAccent)
                        .symbolSize(60)
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
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)
            } else {
                emptyState("No weight data available")
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    private func volumeChart(for exercise: Exercise) -> some View {
        let data = getVolumeProgression(for: exercise)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Volume per Session")
                        .font(.headline)
                    Text("Total volume (weight × reps × sets)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)

            if !data.isEmpty {
                Chart {
                    ForEach(data, id: \.date) { point in
                        BarMark(
                            x: .value("Date", point.date),
                            y: .value("Volume", point.volume)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(4)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let volume = value.as(Double.self) {
                                Text(formatVolume(volume))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .frame(height: 180)
                .padding(.horizontal)
            } else {
                emptyState("No volume data available")
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    private func bestSetsSection(for exercise: Exercise) -> some View {
        let bestSets = getBestSets(for: exercise)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Personal Bests")
                .font(.headline)
                .padding(.horizontal)

            if !bestSets.isEmpty {
                VStack(spacing: 8) {
                    ForEach(bestSets, id: \.type) { best in
                        BestSetRow(best: best)
                    }
                }
                .padding(.horizontal)
            } else {
                emptyState("No data yet - complete some sets!")
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
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
                                    .fontWeight(.medium)
                                Text(exercise.muscleGroup.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedExercise?.id == exercise.id {
                                Image(systemName: "checkmark.circle.fill")
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

    private func emptyState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.3))
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed Properties

    private var last30DaysWorkouts: [Workout] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        return viewModel.workouts.filter { $0.startTime >= thirtyDaysAgo }
    }

    private var totalVolume: Double {
        last30DaysWorkouts.reduce(0) { $0 + $1.totalVolume }
    }

    private var totalPRs: Int {
        viewModel.workouts.reduce(0) { $0 + $1.personalRecordsCount }
    }

    private var workoutsPerWeek: Int {
        let weeks = viewModel.workouts.count > 0 ?
            max(1, Calendar.current.dateComponents([.weekOfYear],
                from: viewModel.workouts.map { $0.startTime }.min() ?? Date(),
                to: Date()).weekOfYear ?? 1) : 1
        return viewModel.workouts.count / weeks
    }

    private var workoutsThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return 0
        }
        return viewModel.workouts.filter { $0.startTime >= weekStart }.count
    }

    private var avgDuration: String {
        let durations = viewModel.workouts.compactMap { $0.duration }
        guard !durations.isEmpty else { return "-" }
        let avg = durations.reduce(0, +) / Double(durations.count)
        return "\(Int(avg / 60))m"
    }

    private var avgRestDays: Int {
        let sortedWorkouts = viewModel.workouts.sorted { $0.startTime < $1.startTime }
        guard sortedWorkouts.count > 1 else { return 0 }

        var totalRestDays = 0
        for i in 1..<sortedWorkouts.count {
            let days = Calendar.current.dateComponents([.day],
                from: sortedWorkouts[i-1].startTime,
                to: sortedWorkouts[i].startTime).day ?? 0
            totalRestDays += max(0, days - 1)
        }
        return totalRestDays / max(1, sortedWorkouts.count - 1)
    }

    private var volumeByWeek: [(week: Date, volume: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: viewModel.workouts) { workout in
            calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.startTime))!
        }

        return grouped.map { (week: $0.key, volume: $0.value.reduce(0) { $0 + $1.totalVolume }) }
            .sorted { $0.week < $1.week }
            .suffix(12)
    }

    private var recentPRs: [PRInfo] {
        var prs: [PRInfo] = []

        for workout in viewModel.workouts.sorted(by: { $0.startTime > $1.startTime }) {
            for workoutExercise in workout.exercises {
                for set in workoutExercise.sets where set.isPersonalRecord {
                    if let exercise = workoutExercise.exercise,
                       let weight = set.weight,
                       let reps = set.reps {
                        prs.append(PRInfo(
                            id: set.id,
                            exerciseName: exercise.name,
                            weight: weight,
                            reps: reps,
                            date: workout.startTime
                        ))
                    }
                }
            }
        }

        return prs
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

    // MARK: - Exercise-specific helpers

    private func getExerciseStats(for exercise: Exercise) -> ExerciseStats {
        var totalVolume = 0.0
        var totalSets = 0
        var workoutCount = 0
        var maxWeight = 0.0
        var maxReps = 0
        var bestSet: (weight: Double, reps: Int)?

        for workout in viewModel.workouts {
            var foundExercise = false
            for workoutExercise in workout.exercises {
                if workoutExercise.exercise?.id == exercise.id {
                    foundExercise = true
                    totalVolume += workoutExercise.totalVolume
                    totalSets += workoutExercise.completedSets.count

                    for set in workoutExercise.completedSets {
                        if let weight = set.weight, let reps = set.reps {
                            if weight > maxWeight {
                                maxWeight = weight
                                maxReps = reps
                                bestSet = (weight, reps)
                            }
                        }
                    }
                }
            }
            if foundExercise {
                workoutCount += 1
            }
        }

        // Calculate estimated 1RM using Brzycki formula: weight × (36 / (37 - reps))
        var estimated1RM = 0.0
        if let best = bestSet, best.reps > 0 && best.reps < 37 {
            estimated1RM = best.weight * (36.0 / (37.0 - Double(best.reps)))
        }

        return ExerciseStats(
            totalVolume: totalVolume,
            totalSets: totalSets,
            workoutCount: workoutCount,
            estimated1RM: estimated1RM
        )
    }

    private func getWeightProgression(for exercise: Exercise) -> [(date: Date, weight: Double)] {
        var results: [(date: Date, weight: Double)] = []

        for workout in viewModel.workouts.sorted(by: { $0.startTime < $1.startTime }) {
            for workoutExercise in workout.exercises {
                if workoutExercise.exercise?.id == exercise.id {
                    let maxWeight = workoutExercise.completedSets
                        .compactMap { $0.weight }
                        .max() ?? 0
                    if maxWeight > 0 {
                        results.append((date: workout.startTime, weight: maxWeight))
                    }
                }
            }
        }

        return results
    }

    private func getVolumeProgression(for exercise: Exercise) -> [(date: Date, volume: Double)] {
        var results: [(date: Date, volume: Double)] = []

        for workout in viewModel.workouts.sorted(by: { $0.startTime < $1.startTime }) {
            for workoutExercise in workout.exercises {
                if workoutExercise.exercise?.id == exercise.id {
                    let volume = workoutExercise.totalVolume
                    if volume > 0 {
                        results.append((date: workout.startTime, volume: volume))
                    }
                }
            }
        }

        return results
    }

    private func getBestSets(for exercise: Exercise) -> [BestSet] {
        var maxWeight: (weight: Double, reps: Int, date: Date)?
        var maxReps: (weight: Double, reps: Int, date: Date)?
        var maxVolume: (weight: Double, reps: Int, volume: Double, date: Date)?

        for workout in viewModel.workouts {
            for workoutExercise in workout.exercises {
                if workoutExercise.exercise?.id == exercise.id {
                    for set in workoutExercise.completedSets {
                        if let weight = set.weight, let reps = set.reps {
                            // Max weight
                            if maxWeight == nil || weight > maxWeight!.weight {
                                maxWeight = (weight, reps, workout.startTime)
                            }

                            // Max reps (at any weight >= 50% of max)
                            let minWeight = (maxWeight?.weight ?? 0) * 0.5
                            if weight >= minWeight {
                                if maxReps == nil || reps > maxReps!.reps {
                                    maxReps = (weight, reps, workout.startTime)
                                }
                            }

                            // Max volume in single set
                            let volume = weight * Double(reps)
                            if maxVolume == nil || volume > maxVolume!.volume {
                                maxVolume = (weight, reps, volume, workout.startTime)
                            }
                        }
                    }
                }
            }
        }

        var results: [BestSet] = []
        if let max = maxWeight {
            results.append(BestSet(type: "Heaviest Weight", weight: max.weight, reps: max.reps, date: max.date))
        }
        if let max = maxReps {
            results.append(BestSet(type: "Most Reps", weight: max.weight, reps: max.reps, date: max.date))
        }
        if let max = maxVolume {
            results.append(BestSet(type: "Highest Volume", weight: max.weight, reps: max.reps, date: max.date))
        }

        return results
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }

    // MARK: - Supporting Types

    enum AnalyticsTab {
        case overview
        case exercise
    }
}

// MARK: - Supporting Views

struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct ConsistencyMetric: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PRRowView: View {
    let pr: PRInfo

    var body: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange, Color.yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(pr.exerciseName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(String(format: "%.1f", pr.weight)) lbs × \(pr.reps) reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(pr.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct BestSetRow: View {
    let best: BestSet

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(best.type)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(String(format: "%.1f", best.weight)) lbs × \(best.reps) reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(best.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Data Models

struct PRInfo {
    let id: UUID
    let exerciseName: String
    let weight: Double
    let reps: Int
    let date: Date
}

struct ExerciseStats {
    let totalVolume: Double
    let totalSets: Int
    let workoutCount: Int
    let estimated1RM: Double
}

struct BestSet {
    let type: String
    let weight: Double
    let reps: Int
    let date: Date
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workout.self, configurations: config)
    let context = container.mainContext

    let exercise = Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell)
    let workout = Workout(startTime: Date().addingTimeInterval(-86400), endTime: Date().addingTimeInterval(-82800))
    let we = WorkoutExercise(workout: workout, exercise: exercise, order: 0)
    let set = ExerciseSet(workoutExercise: we, setNumber: 1, weight: 185, reps: 8, completedAt: Date(), isPersonalRecord: true)

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
