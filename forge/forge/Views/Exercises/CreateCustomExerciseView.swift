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

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise Details") {
                    TextField("Exercise Name", text: $name)

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
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveExercise() {
        let exercise = Exercise(
            name: name,
            muscleGroup: selectedMuscleGroup,
            equipment: selectedEquipment,
            isCustom: true
        )

        modelContext.insert(exercise)
        try? modelContext.save()

        dismiss()

        // Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

#Preview {
    CreateCustomExerciseView()
}
