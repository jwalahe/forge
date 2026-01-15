//
//  AddExerciseSheet.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI
import SwiftData

struct AddExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let viewModel: ActiveWorkoutViewModel
    let onExerciseSelected: (Exercise) -> Void

    @State private var searchText = ""
    @State private var selectedSegment = 0
    @State private var showingCreateExercise = false
    @Query private var allExercises: [Exercise]

    init(viewModel: ActiveWorkoutViewModel, onExerciseSelected: @escaping (Exercise) -> Void) {
        self.viewModel = viewModel
        self.onExerciseSelected = onExerciseSelected
        _allExercises = Query(
            filter: #Predicate<Exercise> { !$0.isArchived },
            sort: \Exercise.name
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search exercises...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()

                // Segment control
                Picker("Filter", selection: $selectedSegment) {
                    Text("All").tag(0)
                    Text("By Muscle").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Exercise list
                List {
                    if selectedSegment == 0 {
                        allExercisesSection
                    } else {
                        byMuscleGroupSections
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateExercise = true
                    } label: {
                        Label("Create", systemImage: "plus.circle.fill")
                            .labelStyle(.titleAndIcon)
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingCreateExercise) {
                CreateExerciseSheet(modelContext: modelContext) { newExercise in
                    selectExercise(newExercise)
                }
            }
        }
    }

    // MARK: - Subviews

    private var allExercisesSection: some View {
        ForEach(filteredExercises) { exercise in
            exerciseRow(exercise)
        }
    }

    private var byMuscleGroupSections: some View {
        ForEach(Exercise.MuscleGroup.allCases, id: \.self) { muscleGroup in
            let exercises = exercisesForMuscleGroup(muscleGroup)
            if !exercises.isEmpty {
                Section(muscleGroup.displayName) {
                    ForEach(exercises) { exercise in
                        exerciseRow(exercise)
                    }
                }
            }
        }
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        Button {
            selectExercise(exercise)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .foregroundColor(.primary)
                        .fontWeight(.medium)

                    HStack(spacing: 8) {
                        Text(exercise.muscleGroup.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(exercise.equipment.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if exercise.isCustom {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(.forgeAccent)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Computed Properties

    private var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return allExercises
        }
        return allExercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func exercisesForMuscleGroup(_ muscleGroup: Exercise.MuscleGroup) -> [Exercise] {
        let exercises = searchText.isEmpty ? allExercises : filteredExercises
        return exercises.filter { $0.muscleGroup == muscleGroup }
    }

    // MARK: - Actions

    private func selectExercise(_ exercise: Exercise) {
        onExerciseSelected(exercise)
        dismiss()

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
        Exercise(name: "Deadlift", muscleGroup: .back, equipment: .barbell)
    ]

    exercises.forEach { context.insert($0) }

    let viewModel = ActiveWorkoutViewModel(modelContext: context)

    return AddExerciseSheet(viewModel: viewModel) { exercise in
        print("Selected: \(exercise.name)")
    }
    .modelContainer(container)
}
