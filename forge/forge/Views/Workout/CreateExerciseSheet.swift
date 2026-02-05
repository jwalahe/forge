//
//  CreateExerciseSheet.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI
import SwiftData

struct CreateExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    let modelContext: ModelContext
    let onExerciseCreated: (Exercise) -> Void

    @State private var exerciseName = ""
    @State private var selectedMuscleGroup: Exercise.MuscleGroup = .chest
    @State private var selectedEquipment: Exercise.Equipment = .dumbbell
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Exercise Name", text: $exerciseName)
                        .focused($isNameFieldFocused)
                        .autocorrectionDisabled()
                } header: {
                    Text("Name")
                } footer: {
                    Text("Enter a descriptive name for your custom exercise")
                }

                Section("Muscle Group") {
                    Picker("Muscle Group", selection: $selectedMuscleGroup) {
                        ForEach(Exercise.MuscleGroup.allCases, id: \.self) { group in
                            Text(group.displayName).tag(group)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .onChange(of: selectedMuscleGroup) { _, _ in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

                Section("Equipment") {
                    Picker("Equipment", selection: $selectedEquipment) {
                        ForEach(Exercise.Equipment.allCases, id: \.self) { equipment in
                            Text(equipment.displayName).tag(equipment)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .onChange(of: selectedEquipment) { _, _ in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
            .navigationTitle("Create Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createExercise()
                    }
                    .fontWeight(.semibold)
                    .disabled(exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                isNameFieldFocused = true
            }
        }
    }

    private func createExercise() {
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let newExercise = Exercise(
            name: trimmedName,
            muscleGroup: selectedMuscleGroup,
            equipment: selectedEquipment,
            isCustom: true
        )

        modelContext.insert(newExercise)
        try? modelContext.save()

        onExerciseCreated(newExercise)

        // Success haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Exercise.self, configurations: config)

    return CreateExerciseSheet(modelContext: container.mainContext) { exercise in
        print("Created: \(exercise.name)")
    }
    .modelContainer(container)
}
