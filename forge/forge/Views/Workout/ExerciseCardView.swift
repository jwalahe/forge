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
        VStack(alignment: .leading, spacing: 16) {
            // Header with enhanced styling
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutExercise.exercise?.name ?? "Unknown Exercise")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    if let muscleGroup = workoutExercise.exercise?.muscleGroup {
                        Text(muscleGroup.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button {
                    showingOptions = true
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary.opacity(0.6))
                        .frame(width: 44, height: 44)
                }
            }

            // Previous performance with enhanced styling
            if let previousWorkoutExercise = viewModel.getPreviousWorkoutExercise(for: workoutExercise.exercise!) {
                previousPerformanceView(previousWorkoutExercise)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Divider()
                .padding(.vertical, 4)

            // Sets with animation
            ForEach(sortedSets) { set in
                let previousSet = getPreviousSet(for: set, from: previousWorkoutExercise)
                SetRowView(set: set, previousSet: previousSet, viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.deleteSet(set)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }

            // Add Set button with enhanced styling
            Button {
                addNewSet()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Add Set")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.forgeAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.forgeAccent.opacity(0.08))
                .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        .confirmationDialog("Exercise Options", isPresented: $showingOptions) {
            Button("Add Note") {
                // TODO: Implement notes
            }
            Button("Remove Exercise", role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.removeExercise(workoutExercise)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Subviews

    private func previousPerformanceView(_ previousWorkoutExercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundColor(.blue)

                Text("Last Time")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                Image(systemName: "hand.tap.fill")
                    .font(.caption2)
                    .foregroundColor(.blue.opacity(0.6))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(previousWorkoutExercise.completedSets) { set in
                        previousSetBadge(set)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.08), Color.blue.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                autoFillFromPrevious(previousWorkoutExercise)
            }
        }
    }

    private func previousSetBadge(_ set: ExerciseSet) -> some View {
        HStack(spacing: 5) {
            if let weight = set.weight {
                Text(String(format: "%.1f", weight))
                    .fontWeight(.semibold)
            }
            Text("×")
                .fontWeight(.medium)
            if let reps = set.reps {
                Text("\(reps)")
                    .fontWeight(.semibold)
            }
        }
        .font(.system(size: 14))
        .foregroundColor(.primary.opacity(0.8))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
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

        // Animate the addition
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
