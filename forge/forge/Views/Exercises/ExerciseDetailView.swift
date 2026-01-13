//
//  ExerciseDetailView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let exercise: Exercise

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Exercise info header
                    exerciseInfo

                    // History placeholder
                    VStack(alignment: .leading, spacing: 16) {
                        Text("History")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        Text("Exercise history and progress graphs will appear here")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var exerciseInfo: some View {
        VStack(spacing: 16) {
            // Muscle group badge
            HStack(spacing: 12) {
                Label(exercise.muscleGroup.displayName, systemImage: "figure.strengthtraining.traditional")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)

                Label(exercise.equipment.displayName, systemImage: "gearshape")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(8)

                if exercise.isCustom {
                    Label("Custom", systemImage: "person.fill")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.forgeAccent.opacity(0.1))
                        .foregroundColor(.forgeAccent)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Exercise.self, configurations: config)
    let context = container.mainContext

    let exercise = Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell)
    context.insert(exercise)

    return ExerciseDetailView(exercise: exercise)
        .modelContainer(container)
}
