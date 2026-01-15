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
                        } label: {
                            Label("Add Exercises", systemImage: "plus.circle")
                                .foregroundColor(.forgeAccent)
                        }
                    } else {
                        ForEach(selectedExercises) { exercise in
                            HStack {
                                Text(exercise.name)
                                Spacer()
                                Text(exercise.muscleGroup.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete(perform: deleteExercise)

                        Button {
                            showingExercisePicker = true
                        } label: {
                            Label("Add More", systemImage: "plus.circle")
                                .foregroundColor(.forgeAccent)
                        }
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
        selectedExercises.remove(atOffsets: offsets)
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
        if selectedExercises.contains(exercise.id) {
            selectedExercises.remove(exercise.id)
        } else {
            selectedExercises.insert(exercise.id)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Template.self, configurations: config)

    return CreateTemplateView(modelContext: container.mainContext)
        .modelContainer(container)
}
