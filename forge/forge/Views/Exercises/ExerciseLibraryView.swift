//
//  ExerciseLibraryView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]

    @State private var searchText = ""
    @State private var selectedMuscleGroup: Exercise.MuscleGroup?
    @State private var selectedExercise: Exercise?
    @State private var showingCreateCustom = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Muscle group filter chips
                muscleGroupFilter

                // Exercise list
                exerciseList
            }
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateCustom = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
            .sheet(isPresented: $showingCreateCustom) {
                CreateCustomExerciseView()
            }
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search exercises...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        searchText = ""
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var muscleGroupFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All filter
                FilterChip(
                    title: "All",
                    isSelected: selectedMuscleGroup == nil,
                    count: exercises.count
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedMuscleGroup = nil
                    }
                }

                // Muscle group filters
                ForEach(Exercise.MuscleGroup.allCases, id: \.self) { group in
                    let count = exercises.filter { $0.muscleGroup == group }.count
                    if count > 0 {
                        FilterChip(
                            title: group.displayName,
                            isSelected: selectedMuscleGroup == group,
                            count: count
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedMuscleGroup = group
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    private var exerciseList: some View {
        List {
            if filteredExercises.isEmpty {
                filteredEmptyState
            } else {
                ForEach(filteredExercises) { exercise in
                    ExerciseRow(exercise: exercise)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedExercise = exercise
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
        }
        .listStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: filteredExercises.count)
    }

    private var filteredEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.forgeMuted, Color.forgeMuted.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, 40)

            VStack(spacing: 8) {
                Text("No Exercises Found")
                    .font(.title3)
                    .fontWeight(.semibold)

                if !searchText.isEmpty {
                    Text("No results for \"\(searchText)\"\(selectedMuscleGroup != nil ? " in \(selectedMuscleGroup!.displayName)" : "").")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else if selectedMuscleGroup != nil {
                    Text("No exercises in \(selectedMuscleGroup!.displayName). Try a different filter or create a custom exercise.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Button {
                showingCreateCustom = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Label("Create Custom Exercise", systemImage: "plus.circle.fill")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .frame(height: AppConstants.secondaryButtonHeight)
                    .background(
                        LinearGradient(
                            colors: [Color.forgeAccent, Color.forgeAccent.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(AppConstants.cornerRadius)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .transition(.opacity)
    }

    // MARK: - Computed Properties

    private var filteredExercises: [Exercise] {
        var filtered = exercises.filter { !$0.isArchived }

        // Filter by muscle group
        if let selectedMuscleGroup = selectedMuscleGroup {
            filtered = filtered.filter { $0.muscleGroup == selectedMuscleGroup }
        }

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered.sorted { $0.name < $1.name }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button {
            action()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color(.systemGray5))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.forgeAccent : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .shadow(
                color: isSelected ? Color.forgeAccent.opacity(0.3) : Color.clear,
                radius: 6,
                x: 0,
                y: 2
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
    }
}

// MARK: - Exercise Row

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 16) {
            // Muscle group icon
            ZStack {
                Circle()
                    .fill(muscleGroupColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: muscleGroupIcon)
                    .font(.title3)
                    .foregroundColor(muscleGroupColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.caption2)
                        Text(exercise.muscleGroup.displayName)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    HStack(spacing: 4) {
                        Image(systemName: equipmentIcon)
                            .font(.caption2)
                        Text(exercise.equipment.displayName)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            if exercise.isCustom {
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundColor(.forgeAccent)
                    .padding(8)
                    .background(Color.forgeAccent.opacity(0.1))
                    .clipShape(Circle())
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var muscleGroupColor: Color {
        switch exercise.muscleGroup {
        case .chest: return .blue
        case .back: return .green
        case .shoulders: return .orange
        case .biceps, .triceps: return .purple
        case .quads, .hamstrings, .glutes, .calves: return .red
        case .core: return .yellow
        case .fullBody: return .indigo
        }
    }

    private var muscleGroupIcon: String {
        switch exercise.muscleGroup {
        case .chest: return "figure.arms.open"
        case .back: return "figure.walk"
        case .shoulders: return "figure.flexibility"
        case .biceps, .triceps: return "figure.strengthtraining.traditional"
        case .quads, .hamstrings, .glutes, .calves: return "figure.run"
        case .core: return "figure.core.training"
        case .fullBody: return "figure.mixed.cardio"
        }
    }

    private var equipmentIcon: String {
        switch exercise.equipment {
        case .barbell: return "minus.circle"
        case .dumbbell: return "circle.lefthalf.filled"
        case .cable: return "cable.connector"
        case .machine: return "gearshape.2"
        case .bodyweight: return "figure.stand"
        case .other: return "ellipsis.circle"
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Exercise.self, configurations: config)
    let context = container.mainContext

    // Add sample exercises
    let exercises = [
        Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell),
        Exercise(name: "Squat", muscleGroup: .quads, equipment: .barbell),
        Exercise(name: "Deadlift", muscleGroup: .back, equipment: .barbell),
        Exercise(name: "Overhead Press", muscleGroup: .shoulders, equipment: .barbell),
        Exercise(name: "Pull-Up", muscleGroup: .back, equipment: .bodyweight),
    ]

    exercises.forEach { context.insert($0) }

    return ExerciseLibraryView()
        .modelContainer(container)
}
