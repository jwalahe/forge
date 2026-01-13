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
    @State private var timerPulse = false
    @State private var completedWorkout: Workout?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Exercise list
                ScrollView {
                    VStack(spacing: 20) {
                        if let workout = viewModel.currentWorkout {
                            if sortedExercises(workout).isEmpty {
                                emptyStateView
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                ForEach(sortedExercises(workout)) { workoutExercise in
                                    ExerciseCardView(
                                        workoutExercise: workoutExercise,
                                        viewModel: viewModel
                                    )
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .move(edge: .trailing).combined(with: .opacity)
                                    ))
                                }
                            }
                        }

                        // Spacing for the bottom button
                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                }

                // Add Exercise button (sticky bottom) with gradient
                VStack {
                    Spacer()
                    Button {
                        showingAddExercise = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Add Exercise")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: AppConstants.primaryButtonHeight)
                        .background(
                            LinearGradient(
                                colors: [Color.forgeAccent, Color.forgeAccent.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Color.forgeAccent.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCancelAlert = true
                    }
                    .foregroundColor(.red)
                }

                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .opacity(timerPulse ? 1.0 : 0.3)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: timerPulse)

                        Text(viewModel.elapsedTime.formattedDuration)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.forgeAccent, Color.forgeAccent.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") {
                        finishWorkout()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(canFinishWorkout ? .forgeSuccess : .secondary)
                    .disabled(!canFinishWorkout)
                }
            }
            .onAppear {
                timerPulse = true
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
                if let workout = completedWorkout {
                    WorkoutSummaryView(workout: workout, viewModel: viewModel) {
                        completedWorkout = nil
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.forgeAccent, Color.forgeAccent.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, 60)

            VStack(spacing: 8) {
                Text("Ready to Start")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Add your first exercise to begin tracking")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
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
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            viewModel.addExercise(exercise)
        }

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func finishWorkout() {
        // Capture the workout reference before it's cleared by finishWorkout()
        completedWorkout = viewModel.currentWorkout
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
