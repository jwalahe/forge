//
//  CreateTemplateView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI
import SwiftData

struct CreateTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    let modelContext: ModelContext

    @State private var templateName = ""
    @State private var selectedExercises: [Exercise] = []
    @State private var showingExercisePicker = false
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Template Name", text: $templateName)
                        .focused($isNameFieldFocused)
                } header: {
                    Text("Name")
                } footer: {
                    Text("e.g., Push Day A, Leg Day, Upper Body")
                }

                Section {
                    if selectedExercises.isEmpty {
                        Button {
                            showingExercisePicker = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Label("Add Exercises", systemImage: "plus.circle")
                                .foregroundColor(.forgeAccent)
                        }
                        .frame(minHeight: AppConstants.minTouchTarget)
                    } else {
                        ForEach(selectedExercises) { exercise in
                            HStack {
                                Text(exercise.name)
                                Spacer()
                                Text(exercise.muscleGroup.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                        }
                        .onDelete(perform: deleteExercise)

                        Button {
                            showingExercisePicker = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Label("Add More", systemImage: "plus.circle")
                                .foregroundColor(.forgeAccent)
                        }
                        .frame(minHeight: AppConstants.minTouchTarget)
                    }
                } header: {
                    Text("Exercises")
                } footer: {
                    Text("\(selectedExercises.count) exercise(s) selected")
                }
            }
            .navigationTitle("Create Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .fontWeight(.semibold)
                    .disabled(templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedExercises.isEmpty)
                }
            }
            .onAppear {
                isNameFieldFocused = true
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(modelContext: modelContext) { exercises in
                    for exercise in exercises {
                        if !selectedExercises.contains(where: { $0.id == exercise.id }) {
                            selectedExercises.append(exercise)
                        }
                    }
                }
            }
        }
    }

    private func deleteExercise(at offsets: IndexSet) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedExercises.remove(atOffsets: offsets)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func saveTemplate() {
        let trimmedName = templateName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !selectedExercises.isEmpty else { return }

        let templateRepo = TemplateRepository(modelContext: modelContext)
        _ = templateRepo.createTemplate(name: trimmedName, exercises: selectedExercises)

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }
}

// MARK: - Exercise Picker

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let modelContext: ModelContext
    let onExercisesSelected: ([Exercise]) -> Void

    @Query(filter: #Predicate<Exercise> { !$0.isArchived }, sort: \Exercise.name) private var allExercises: [Exercise]
    @State private var selectedExercises: Set<UUID> = []
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredExercises) { exercise in
                    Button {
                        toggleExercise(exercise)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .foregroundColor(.primary)
                                Text(exercise.muscleGroup.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedExercises.contains(exercise.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.forgeAccent)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Select Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        let exercises = allExercises.filter { selectedExercises.contains($0.id) }
                        onExercisesSelected(exercises)
                        dismiss()
                    }
                    .disabled(selectedExercises.isEmpty)
                }
            }
        }
    }

    private var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return allExercises
        }
        return allExercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func toggleExercise(_ exercise: Exercise) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedExercises.contains(exercise.id) {
                selectedExercises.remove(exercise.id)
            } else {
                selectedExercises.insert(exercise.id)
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Template.self, configurations: config)

    return CreateTemplateView(modelContext: container.mainContext)
        .modelContainer(container)
}
