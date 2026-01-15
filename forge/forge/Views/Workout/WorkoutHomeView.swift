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
    @State private var pulseAnimation = false
    @Query(sort: \Template.lastUsedAt, order: .reverse) private var templates: [Template]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header with gradient
                    headerSection

                    // Start/Continue Workout Button
                    if let vm = viewModel, vm.currentWorkout != nil {
                        continueWorkoutButton
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        startWorkoutButton
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Template quick-start section
                    if !templates.isEmpty {
                        templateQuickStartSection
                    }

                    // Quick tips card
                    quickTipsCard

                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
        }
        .onAppear {
            setupViewModel()
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        .fullScreenCover(isPresented: $showingActiveWorkout) {
            if let vm = viewModel {
                ActiveWorkoutView(viewModel: vm)
                    .onDisappear {
                        setupViewModel()
                    }
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)

                Text("FORGE")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            Text("Build Your Best Self")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var startWorkoutButton: some View {
        Button {
            startWorkout()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)

                Text("Start Workout")
                    .fontWeight(.bold)
                    .font(.title3)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppConstants.primaryButtonHeight)
            .background(
                LinearGradient(
                    colors: [Color.forgeAccent, Color.forgeAccent.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: Color.forgeAccent.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 24)
    }

    private var continueWorkoutButton: some View {
        Button {
            continueWorkout()
        } label: {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(pulseAnimation ? 1.2 : 0.8)

                    if let vm = viewModel {
                        Text(vm.elapsedTime.formattedDuration)
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.bold)
                    }

                    Image(systemName: "timer")
                        .font(.title3)
                }

                Text("Continue Workout")
                    .fontWeight(.semibold)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppConstants.primaryButtonHeight + 20)
            .background(
                LinearGradient(
                    colors: [Color.forgeSuccess, Color.forgeSuccess.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: Color.forgeSuccess.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .padding(.horizontal, 24)
    }

    private var quickTipsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                    .font(.title3)

                Text("Quick Tips")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            VStack(alignment: .leading, spacing: 12) {
                tipRow(icon: "arrow.up.circle.fill", text: "Green arrows mean you beat last time", color: .green)
                tipRow(icon: "arrow.down.circle.fill", text: "Red arrows show when you're below", color: .red)
                tipRow(icon: "checkmark.circle.fill", text: "Tap checkmark to complete a set", color: .blue)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }

    private func tipRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.body)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var templateQuickStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Start")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                NavigationLink(destination: TemplateListView(modelContext: modelContext)) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(.forgeAccent)
                }
            }
            .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(templates.prefix(5)) { template in
                        templateQuickStartCard(template)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func templateQuickStartCard(_ template: Template) -> some View {
        Button {
            startWorkoutFromTemplate(template)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.forgeAccent)
                        .font(.title3)

                    Spacer()

                    Text("\(template.exerciseCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(template.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let lastUsed = template.lastUsedAt {
                    Text("Last: \(lastUsed.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .frame(width: 140, height: 110)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Actions

    private func setupViewModel() {
        if viewModel == nil {
            viewModel = ActiveWorkoutViewModel(modelContext: modelContext)
        }
        viewModel?.loadInProgressWorkout()
    }

    private func startWorkout() {
        if viewModel == nil {
            viewModel = ActiveWorkoutViewModel(modelContext: modelContext)
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            viewModel?.startNewWorkout()
            showingActiveWorkout = true
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func continueWorkout() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showingActiveWorkout = true
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func startWorkoutFromTemplate(_ template: Template) {
        if viewModel == nil {
            viewModel = ActiveWorkoutViewModel(modelContext: modelContext)
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            viewModel?.startNewWorkout()

            // Add exercises from template
            for templateExercise in template.exercises.sorted(by: { $0.order < $1.order }) {
                if let exercise = templateExercise.exercise {
                    viewModel?.addExercise(exercise)
                }
            }

            // Update template last used
            let templateRepo = TemplateRepository(modelContext: modelContext)
            templateRepo.updateTemplateLastUsed(template)

            showingActiveWorkout = true
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workout.self, configurations: config)

    return WorkoutHomeView()
        .modelContainer(container)
}
