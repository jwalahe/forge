//
//  WorkoutSummaryView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI
import SwiftData

struct WorkoutSummaryView: View {
    let workout: Workout
    let viewModel: ActiveWorkoutViewModel
    let onDismiss: () -> Void

    @State private var workoutName = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Checkmark animation
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.forgeSuccess)

                    Text("Workout Complete")
                        .font(.title2)
                        .fontWeight(.bold)

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            title: "Duration",
                            value: workout.duration?.shortDuration ?? "0 min"
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

                    // Exercise summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Exercises")
                            .font(.headline)

                        ForEach(sortedExercises) { workoutExercise in
                            HStack {
                                Text(workoutExercise.exercise?.name ?? "Unknown")
                                Spacer()
                                Text("\(workoutExercise.completedSets.count) sets")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(AppConstants.cornerRadius)

                    // Optional name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Workout Name (Optional)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextField("e.g., Push Day A", text: $workoutName)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Optional notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (Optional)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextEditor(text: $notes)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveAndDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var sortedExercises: [WorkoutExercise] {
        workout.exercises.sorted { $0.order < $1.order }
    }

    // MARK: - Actions

    private func saveAndDismiss() {
        if !workoutName.isEmpty {
            workout.name = workoutName
        }
        if !notes.isEmpty {
            workout.notes = notes
        }

        onDismiss()

        // Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(AppConstants.cornerRadius)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workout.self, configurations: config)
    let context = container.mainContext

    let exercise1 = Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell)
    let exercise2 = Exercise(name: "Squat", muscleGroup: .quads, equipment: .barbell)

    let workout = Workout(startTime: Date().addingTimeInterval(-3600), endTime: Date())
    let we1 = WorkoutExercise(workout: workout, exercise: exercise1, order: 0)
    let we2 = WorkoutExercise(workout: workout, exercise: exercise2, order: 1)

    let set1 = ExerciseSet(workoutExercise: we1, setNumber: 1, weight: 185, reps: 8, completedAt: Date())
    let set2 = ExerciseSet(workoutExercise: we1, setNumber: 2, weight: 185, reps: 7, completedAt: Date())
    let set3 = ExerciseSet(workoutExercise: we2, setNumber: 1, weight: 225, reps: 5, completedAt: Date())

    context.insert(exercise1)
    context.insert(exercise2)
    context.insert(workout)
    context.insert(we1)
    context.insert(we2)
    context.insert(set1)
    context.insert(set2)
    context.insert(set3)

    we1.sets = [set1, set2]
    we2.sets = [set3]
    workout.exercises = [we1, we2]

    let viewModel = ActiveWorkoutViewModel(modelContext: context)

    return WorkoutSummaryView(workout: workout, viewModel: viewModel) {
        print("Dismissed")
    }
    .modelContainer(container)
}
