//
//  WorkoutDetailView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let workout: Workout

    @State private var showingRepeatWorkout = false
    @State private var activeWorkoutViewModel: ActiveWorkoutViewModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header stats
                    statsGrid

                    // Exercises
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Exercises")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        ForEach(sortedExercises) { workoutExercise in
                            exerciseDetailCard(workoutExercise)
                        }
                    }

                    // Notes
                    if let notes = workout.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text(notes)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(AppConstants.cornerRadius)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(workout.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        repeatWorkout()
                    } label: {
                        Label("Repeat", systemImage: "arrow.clockwise")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingRepeatWorkout) {
                if let viewModel = activeWorkoutViewModel {
                    ActiveWorkoutView(viewModel: viewModel)
                        .onDisappear {
                            dismiss()
                        }
                }
            }
        }
    }

    // MARK: - Subviews

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "Duration",
                value: workout.duration?.shortDuration ?? "N/A"
            )

            StatCard(
                title: "Volume",
                value: String(format: "%.0f lbs", workout.totalVolume)
            )

            StatCard(
                title: "Sets",
                value: "\(workout.totalSets)"
            )

            StatCard(
                title: "Exercises",
                value: "\(workout.exercises.count)"
            )
        }
        .padding(.horizontal)
    }

    private func exerciseDetailCard(_ workoutExercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(workoutExercise.exercise?.name ?? "Unknown")
                .font(.headline)

            // Sets
            ForEach(workoutExercise.completedSets) { set in
                HStack {
                    Text("Set \(set.setNumber)")
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)

                    if let weight = set.weight, let reps = set.reps {
                        Text("\(String(format: "%.1f", weight)) lbs × \(reps)")
                            .fontWeight(.medium)
                    }

                    Spacer()

                    if set.isPersonalRecord {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.orange)
                    }
                }
                .font(.subheadline)
            }

            // Notes
            if let notes = workoutExercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }

            // Volume
            Text("Volume: \(String(format: "%.0f lbs", workoutExercise.totalVolume))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(AppConstants.cornerRadius)
        .padding(.horizontal)
    }

    // MARK: - Computed Properties

    private var sortedExercises: [WorkoutExercise] {
        workout.exercises.sorted { $0.order < $1.order }
    }

    // MARK: - Actions

    private func repeatWorkout() {
        let viewModel = ActiveWorkoutViewModel(modelContext: modelContext)
        viewModel.startNewWorkout()

        // Add all exercises from the past workout
        for workoutExercise in sortedExercises {
            guard let exercise = workoutExercise.exercise else { continue }
            viewModel.addExercise(exercise)
        }

        activeWorkoutViewModel = viewModel
        showingRepeatWorkout = true

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workout.self, configurations: config)
    let context = container.mainContext

    let exercise1 = Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell)
    let exercise2 = Exercise(name: "Squat", muscleGroup: .quads, equipment: .barbell)

    let workout = Workout(
        name: "Push Day A",
        startTime: Date().addingTimeInterval(-7200),
        endTime: Date().addingTimeInterval(-3600),
        notes: "Felt strong today!"
    )
    let we1 = WorkoutExercise(workout: workout, exercise: exercise1, order: 0)
    let we2 = WorkoutExercise(workout: workout, exercise: exercise2, order: 1)

    let set1 = ExerciseSet(workoutExercise: we1, setNumber: 1, weight: 185, reps: 8, completedAt: Date())
    let set2 = ExerciseSet(workoutExercise: we1, setNumber: 2, weight: 185, reps: 7, completedAt: Date())
    let set3 = ExerciseSet(workoutExercise: we1, setNumber: 3, weight: 190, reps: 6, completedAt: Date(), isPersonalRecord: true)
    let set4 = ExerciseSet(workoutExercise: we2, setNumber: 1, weight: 225, reps: 5, completedAt: Date())
    let set5 = ExerciseSet(workoutExercise: we2, setNumber: 2, weight: 225, reps: 5, completedAt: Date())

    context.insert(exercise1)
    context.insert(exercise2)
    context.insert(workout)
    context.insert(we1)
    context.insert(we2)
    context.insert(set1)
    context.insert(set2)
    context.insert(set3)
    context.insert(set4)
    context.insert(set5)

    we1.sets = [set1, set2, set3]
    we2.sets = [set4, set5]
    workout.exercises = [we1, we2]

    return WorkoutDetailView(workout: workout)
        .modelContainer(container)
}
