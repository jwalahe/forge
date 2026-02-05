//
//  CreateCustomExerciseView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI
import SwiftData

struct CreateCustomExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var selectedMuscleGroup: Exercise.MuscleGroup = .chest
    @State private var selectedEquipment: Exercise.Equipment = .barbell
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise Details") {
                    TextField("Exercise Name", text: $name)
                        .focused($isNameFieldFocused)
                        .autocorrectionDisabled()

                    Picker("Muscle Group", selection: $selectedMuscleGroup) {
                        ForEach(Exercise.MuscleGroup.allCases, id: \.self) { group in
                            Text(group.displayName).tag(group)
                        }
                    }

                    Picker("Equipment", selection: $selectedEquipment) {
                        ForEach(Exercise.Equipment.allCases, id: \.self) { equipment in
                            Text(equipment.displayName).tag(equipment)
                        }
                    }
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExercise()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                isNameFieldFocused = true
            }
            .onChange(of: selectedMuscleGroup) { _, _ in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            .onChange(of: selectedEquipment) { _, _ in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }

    private func saveExercise() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let exercise = Exercise(
            name: trimmedName,
            muscleGroup: selectedMuscleGroup,
            equipment: selectedEquipment,
            isCustom: true
        )

        modelContext.insert(exercise)
        try? modelContext.save()

        // Success haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        dismiss()
    }
}

#Preview {
    CreateCustomExerciseView()
}
