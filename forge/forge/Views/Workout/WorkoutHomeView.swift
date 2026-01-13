//
//  WorkoutHomeView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI
import SwiftData

struct WorkoutHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ActiveWorkoutViewModel?
    @State private var showingActiveWorkout = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("FORGE")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 40)

                    // Start/Continue Workout Button
                    if let vm = viewModel, vm.currentWorkout != nil {
                        continueWorkoutButton
                    } else {
                        startWorkoutButton
                    }

                    // Recent Exercises (placeholder for now)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Start")
                            .font(.headline)
                            .padding(.horizontal)

                        Text("Start a workout to see your recent exercises here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()
                }
            }
        }
        .onAppear {
            setupViewModel()
        }
        .fullScreenCover(isPresented: $showingActiveWorkout) {
            if let vm = viewModel {
                ActiveWorkoutView(viewModel: vm)
                    .onDisappear {
                        // Refresh state when returning
                        setupViewModel()
                    }
            }
        }
    }

    // MARK: - Subviews

    private var startWorkoutButton: some View {
        Button {
            startWorkout()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Workout")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppConstants.primaryButtonHeight)
            .background(Color.forgeAccent)
            .foregroundColor(.white)
            .cornerRadius(AppConstants.cornerRadius)
        }
        .padding(.horizontal)
    }

    private var continueWorkoutButton: some View {
        Button {
            continueWorkout()
        } label: {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "timer")
                    if let vm = viewModel {
                        Text(vm.elapsedTime.formattedDuration)
                            .font(.system(.title3, design: .monospaced))
                    }
                }

                Text("Continue Workout")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppConstants.primaryButtonHeight + 20)
            .background(Color.forgeSuccess)
            .foregroundColor(.white)
            .cornerRadius(AppConstants.cornerRadius)
        }
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func setupViewModel() {
        if viewModel == nil {
            viewModel = ActiveWorkoutViewModel(modelContext: modelContext)
        }

        // Check for in-progress workout
        viewModel?.loadInProgressWorkout()
    }

    private func startWorkout() {
        if viewModel == nil {
            viewModel = ActiveWorkoutViewModel(modelContext: modelContext)
        }

        viewModel?.startNewWorkout()
        showingActiveWorkout = true

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func continueWorkout() {
        showingActiveWorkout = true

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workout.self, configurations: config)

    return WorkoutHomeView()
        .modelContainer(container)
}
