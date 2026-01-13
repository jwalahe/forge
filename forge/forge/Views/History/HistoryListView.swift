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
                Section(date.workoutDateString) {
                    ForEach(workouts) { workout in
                        WorkoutRowView(workout: workout)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedWorkout = workout
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.deleteWorkout(workout)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .refreshable {
            viewModel.loadWorkouts()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Workouts Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Your workout history will appear here after you complete your first session")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.displayName)
                    .font(.headline)

                Spacer()

                if let duration = workout.duration {
                    Text(duration.shortDuration)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 16) {
                Label("\(workout.exercises.count) exercises", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Label("\(workout.totalSets) sets", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if workout.totalVolume > 0 {
                    Label(String(format: "%.0f lbs", workout.totalVolume), systemImage: "scalemass")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Exercise preview
            if !workout.exercises.isEmpty {
                Text(exercisePreview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
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
