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
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

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

                            VStack(spacing: 16) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 40))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.forgeAccent, Color.forgeAccent.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                Text("Progress tracking coming soon")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(AppConstants.cornerRadius)
                            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(AppConstants.cornerRadius)

                Label(exercise.equipment.displayName, systemImage: "gearshape")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(AppConstants.cornerRadius)

                if exercise.isCustom {
                    Label("Custom", systemImage: "person.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.forgeAccent.opacity(0.1))
                        .foregroundColor(.forgeAccent)
                        .cornerRadius(AppConstants.cornerRadius)
                        .transition(.scale.combined(with: .opacity))
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
