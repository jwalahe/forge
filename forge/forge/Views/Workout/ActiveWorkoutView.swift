//
//  ActiveWorkoutView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: ActiveWorkoutViewModel

    @State private var showingAddExercise = false
    @State private var showingCancelAlert = false
    @State private var showingSummary = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Exercise list
                ScrollView {
                    VStack(spacing: 16) {
                        if let workout = viewModel.currentWorkout {
                            ForEach(sortedExercises(workout)) { workoutExercise in
                                ExerciseCardView(
                                    workoutExercise: workoutExercise,
                                    viewModel: viewModel
                                )
                            }
                        }

                        // Spacing for the bottom button
                        Color.clear.frame(height: 80)
                    }
                    .padding()
                }

                // Add Exercise button (sticky bottom)
                VStack {
                    Spacer()
                    Button {
                        showingAddExercise = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Exercise")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: AppConstants.primaryButtonHeight)
                        .background(Color.forgeAccent)
                        .foregroundColor(.white)
                        .cornerRadius(AppConstants.cornerRadius)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
                    }
                    .padding()
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCancelAlert = true
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text(viewModel.elapsedTime.formattedDuration)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.forgeAccent)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") {
                        finishWorkout()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canFinishWorkout)
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseSheet(viewModel: viewModel) { exercise in
                    addExercise(exercise)
                }
            }
            .alert("Cancel Workout?", isPresented: $showingCancelAlert) {
                Button("Keep Going", role: .cancel) {}
                Button("Discard", role: .destructive) {
                    viewModel.cancelWorkout()
                    dismiss()
                }
            } message: {
                Text("Your workout progress will be lost.")
            }
            .fullScreenCover(isPresented: $showingSummary) {
                if let workout = viewModel.currentWorkout {
                    WorkoutSummaryView(workout: workout, viewModel: viewModel) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var canFinishWorkout: Bool {
        guard let workout = viewModel.currentWorkout else { return false }
        // Must have at least one completed set
        return workout.exercises.contains { !$0.completedSets.isEmpty }
    }

    private func sortedExercises(_ workout: Workout) -> [WorkoutExercise] {
        workout.exercises.sorted { $0.order < $1.order }
    }

    // MARK: - Actions

    private func addExercise(_ exercise: Exercise) {
        withAnimation {
            viewModel.addExercise(exercise)
        }

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func finishWorkout() {
        viewModel.finishWorkout()
        showingSummary = true
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workout.self, configurations: config)
    let viewModel = ActiveWorkoutViewModel(modelContext: container.mainContext)
    viewModel.startNewWorkout()

    return ActiveWorkoutView(viewModel: viewModel)
        .modelContainer(container)
}
