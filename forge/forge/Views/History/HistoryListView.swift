//
//  HistoryListView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HistoryViewModel?
    @State private var showingCalendar = false
    @State private var selectedWorkout: Workout?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel, !viewModel.workouts.isEmpty {
                    workoutList(viewModel: viewModel)
                } else {
                    emptyState
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCalendar.toggle()
                    } label: {
                        Image(systemName: showingCalendar ? "list.bullet" : "calendar")
                    }
                }
            }
            .onAppear {
                setupViewModel()
            }
            .sheet(isPresented: $showingCalendar) {
                if let viewModel = viewModel {
                    CalendarView(viewModel: viewModel)
                }
            }
            .sheet(item: $selectedWorkout) { workout in
                WorkoutDetailView(workout: workout)
            }
        }
    }

    // MARK: - Subviews

    private func workoutList(viewModel: HistoryViewModel) -> some View {
        List {
            ForEach(groupedWorkouts(viewModel.workouts), id: \.key) { date, workouts in
                Section {
                    ForEach(workouts) { workout in
                        WorkoutRowView(workout: workout)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedWorkout = workout
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.deleteWorkout(workout)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    Text(date.workoutDateString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.loadWorkouts()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.forgeAccent.opacity(0.15), Color.forgeAccent.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.forgeAccent, Color.forgeAccent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 40)

            VStack(spacing: 12) {
                Text("No Workouts Yet")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Your workout history will appear here after you complete your first session")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func setupViewModel() {
        if viewModel == nil {
            viewModel = HistoryViewModel(modelContext: modelContext)
        }
        viewModel?.loadWorkouts()
    }

    private func groupedWorkouts(_ workouts: [Workout]) -> [(key: Date, value: [Workout])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: workouts) { workout in
            calendar.startOfDay(for: workout.startTime)
        }
        return grouped.sorted { $0.key > $1.key }
    }
}

// MARK: - Workout Row View

struct WorkoutRowView: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(workout.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)

                    if let duration = workout.duration {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text(duration.shortDuration)
                                .font(.subheadline)
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.forgeAccent, Color.forgeAccent.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.5))
            }

            Divider()

            HStack(spacing: 20) {
                statBadge(
                    icon: "figure.strengthtraining.traditional",
                    value: "\(workout.exercises.count)",
                    label: "exercises",
                    color: .blue
                )

                statBadge(
                    icon: "checkmark.circle.fill",
                    value: "\(workout.totalSets)",
                    label: "sets",
                    color: .green
                )

                if workout.totalVolume > 0 {
                    statBadge(
                        icon: "scalemass.fill",
                        value: String(format: "%.0fk", workout.totalVolume / 1000),
                        label: "volume",
                        color: .orange
                    )
                }
            }

            // Exercise preview
            if !workout.exercises.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))

                    Text(exercisePreview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func statBadge(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var exercisePreview: String {
        let exerciseNames = workout.exercises
            .sorted { $0.order < $1.order }
            .compactMap { $0.exercise?.name }
            .prefix(3)

        if exerciseNames.count > 2 {
            return Array(exerciseNames.prefix(2)).joined(separator: ", ") + "..."
        }
        return exerciseNames.joined(separator: ", ")
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workout.self, configurations: config)
    let context = container.mainContext

    // Create sample workouts
    let exercise1 = Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell)
    let exercise2 = Exercise(name: "Squat", muscleGroup: .quads, equipment: .barbell)

    let workout = Workout(startTime: Date().addingTimeInterval(-86400), endTime: Date().addingTimeInterval(-82800))
    let we1 = WorkoutExercise(workout: workout, exercise: exercise1, order: 0)
    let we2 = WorkoutExercise(workout: workout, exercise: exercise2, order: 1)

    let set1 = ExerciseSet(workoutExercise: we1, setNumber: 1, weight: 185, reps: 8, completedAt: Date())
    let set2 = ExerciseSet(workoutExercise: we1, setNumber: 2, weight: 185, reps: 7, completedAt: Date())

    context.insert(exercise1)
    context.insert(exercise2)
    context.insert(workout)
    context.insert(we1)
    context.insert(we2)
    context.insert(set1)
    context.insert(set2)

    we1.sets = [set1, set2]
    workout.exercises = [we1, we2]

    return HistoryListView()
        .modelContainer(container)
}
