//
//  ExerciseCardView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI
import SwiftData

struct ExerciseCardView: View {
    let workoutExercise: WorkoutExercise
    let viewModel: ActiveWorkoutViewModel

    @State private var showingOptions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(workoutExercise.exercise?.name ?? "Unknown Exercise")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    showingOptions = true
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .frame(width: 44, height: 44)
                }
            }

            // Previous performance
            if let previousWorkoutExercise = viewModel.getPreviousWorkoutExercise(for: workoutExercise.exercise!) {
                previousPerformanceView(previousWorkoutExercise)
            }

            Divider()

            // Sets
            ForEach(sortedSets) { set in
                let previousSet = getPreviousSet(for: set, from: previousWorkoutExercise)
                SetRowView(set: set, previousSet: previousSet, viewModel: viewModel)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation {
                                viewModel.deleteSet(set)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }

            // Add Set button
            Button {
                addNewSet()
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Set")
                }
                .foregroundColor(.forgeAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(AppConstants.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .confirmationDialog("Exercise Options", isPresented: $showingOptions) {
            Button("Add Note") {
                // TODO: Implement notes
            }
            Button("Remove Exercise", role: .destructive) {
                withAnimation {
                    viewModel.removeExercise(workoutExercise)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Subviews

    private func previousPerformanceView(_ previousWorkoutExercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Last Time")
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(previousWorkoutExercise.completedSets) { set in
                        previousSetBadge(set)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .onTapGesture {
            autoFillFromPrevious(previousWorkoutExercise)
        }
    }

    private func previousSetBadge(_ set: ExerciseSet) -> some View {
        HStack(spacing: 4) {
            if let weight = set.weight {
                Text(String(format: "%.1f", weight))
            }
            Text("×")
            if let reps = set.reps {
                Text("\(reps)")
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }

    // MARK: - Computed Properties

    private var sortedSets: [ExerciseSet] {
        workoutExercise.sets.sorted { $0.setNumber < $1.setNumber }
    }

    private var previousWorkoutExercise: WorkoutExercise? {
        guard let exercise = workoutExercise.exercise else { return nil }
        return viewModel.getPreviousWorkoutExercise(for: exercise)
    }

    // MARK: - Helper Methods

    private func getPreviousSet(for currentSet: ExerciseSet, from previousWorkoutExercise: WorkoutExercise?) -> ExerciseSet? {
        guard let previousWorkoutExercise = previousWorkoutExercise else { return nil }
        let previousSets = previousWorkoutExercise.completedSets.sorted { $0.setNumber < $1.setNumber }

        // Match by set number
        if currentSet.setNumber <= previousSets.count {
            return previousSets[currentSet.setNumber - 1]
        }
        return nil
    }

    private func addNewSet() {
        let setNumber = workoutExercise.sets.count + 1

        // Try to auto-fill from previous set in this workout
        if let lastSet = sortedSets.last {
            viewModel.addSet(to: workoutExercise, weight: lastSet.weight, reps: lastSet.reps)
        } else if let previousWorkoutExercise = previousWorkoutExercise,
                  let firstPreviousSet = previousWorkoutExercise.completedSets.first {
            // Auto-fill from previous workout
            viewModel.addSet(to: workoutExercise, weight: firstPreviousSet.weight, reps: firstPreviousSet.reps)
        } else {
            viewModel.addSet(to: workoutExercise, weight: nil, reps: nil)
        }

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func autoFillFromPrevious(_ previousWorkoutExercise: WorkoutExercise) {
        // Clear current sets and recreate from previous
        for set in workoutExercise.sets {
            viewModel.deleteSet(set)
        }

        for previousSet in previousWorkoutExercise.completedSets {
            viewModel.addSet(to: workoutExercise, weight: previousSet.weight, reps: previousSet.reps)
        }

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workout.self, configurations: config)
    let context = container.mainContext

    let exercise = Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell)
    let workout = Workout()
    let workoutExercise = WorkoutExercise(workout: workout, exercise: exercise, order: 0)
    let set1 = ExerciseSet(workoutExercise: workoutExercise, setNumber: 1, weight: 185, reps: 8)
    let set2 = ExerciseSet(workoutExercise: workoutExercise, setNumber: 2, weight: 185, reps: 7)

    context.insert(exercise)
    context.insert(workout)
    context.insert(workoutExercise)
    context.insert(set1)
    context.insert(set2)
    workoutExercise.sets = [set1, set2]

    let viewModel = ActiveWorkoutViewModel(modelContext: context)

    return ExerciseCardView(workoutExercise: workoutExercise, viewModel: viewModel)
        .padding()
}
