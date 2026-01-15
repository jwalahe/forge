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
    @State private var showingWorkoutNotes = false
    @State private var workoutNotesText = ""
    @State private var timerPulse = false
    @State private var completedWorkout: Workout?
    @Environment(\.editMode) private var editMode

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
                                .onMove { source, destination in
                                    moveExercises(from: source, to: destination)
                                }
                            }
                        }

                        // Spacing for the bottom button
                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
                .scrollDismissesKeyboard(.interactively)

                // Rest timer banner (if active)
                if viewModel.isRestTimerActive {
                    VStack {
                        Spacer()
                        restTimerBanner
                            .padding(.horizontal)
                            .padding(.bottom, 84)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
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
                    VStack(spacing: 2) {
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

                        if viewModel.totalSetsCompleted > 0 {
                            Text("\(viewModel.totalSetsCompleted) sets • \(Int(viewModel.totalVolume)) lbs")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
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

                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        workoutNotesText = viewModel.currentWorkout?.notes ?? ""
                        showingWorkoutNotes = true
                    } label: {
                        Image(systemName: viewModel.currentWorkout?.notes == nil ? "note.text" : "note.text.badge.plus")
                            .foregroundColor(.orange)
                    }
                }

                ToolbarItem(placement: .secondaryAction) {
                    if let workout = viewModel.currentWorkout, !workout.exercises.isEmpty {
                        EditButton()
                            .foregroundColor(.forgeAccent)
                    }
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
            .sheet(isPresented: $showingWorkoutNotes) {
                workoutNotesSheet
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

    private var restTimerBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Rest Timer")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text(formattedRestTime)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }

            Spacer()

            // +30s button
            Button {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    viewModel.addRestTime(30)
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Text("+30s")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(6)
            }

            // Pause/Resume button
            Button {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    if viewModel.isRestTimerPaused {
                        viewModel.resumeRestTimer()
                    } else {
                        viewModel.pauseRestTimer()
                    }
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: viewModel.isRestTimerPaused ? "play.fill" : "pause.fill")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .frame(width: 32, height: 32)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(6)
            }

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.skipRestTimer()
                }
            } label: {
                Text("Skip")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.forgeAccent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.forgeAccent.opacity(0.15))
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: -2)
    }

    private var workoutNotesSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add general notes about this workout session.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                TextEditor(text: $workoutNotesText)
                    .font(.body)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .frame(minHeight: 150)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Workout Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingWorkoutNotes = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWorkoutNotes()
                        showingWorkoutNotes = false
                    }
                    .fontWeight(.semibold)
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

    private var formattedRestTime: String {
        let minutes = viewModel.restTimeRemaining / 60
        let seconds = viewModel.restTimeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
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

    private func saveWorkoutNotes() {
        guard let workout = viewModel.currentWorkout else { return }
        let trimmedNotes = workoutNotesText.trimmingCharacters(in: .whitespacesAndNewlines)
        workout.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        guard let workout = viewModel.currentWorkout else { return }
        var exercises = sortedExercises(workout)
        exercises.move(fromOffsets: source, toOffset: destination)

        // Update order property for all affected exercises
        for (index, exercise) in exercises.enumerated() {
            exercise.order = index
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
