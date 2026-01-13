//
//  TemplateRepository.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import Foundation
import SwiftData

@MainActor
class TemplateRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func createTemplate(name: String, exercises: [Exercise]) -> Template {
        let template = Template(name: name)
        modelContext.insert(template)

        for (index, exercise) in exercises.enumerated() {
            let templateExercise = TemplateExercise(
                template: template,
                exercise: exercise,
                order: index
            )
            modelContext.insert(templateExercise)
            template.exercises.append(templateExercise)
        }

        try? modelContext.save()
        return template
    }

    func createTemplateFromWorkout(_ workout: Workout, name: String) -> Template {
        let template = Template(name: name)
        modelContext.insert(template)

        let sortedExercises = workout.exercises.sorted { $0.order < $1.order }

        for workoutExercise in sortedExercises {
            guard let exercise = workoutExercise.exercise else { continue }

            let templateExercise = TemplateExercise(
                template: template,
                exercise: exercise,
                order: workoutExercise.order,
                defaultSets: workoutExercise.sets.count
            )
            modelContext.insert(templateExercise)
            template.exercises.append(templateExercise)
        }

        try? modelContext.save()
        return template
    }

    // MARK: - Read

    func fetchAllTemplates() -> [Template] {
        let descriptor = FetchDescriptor<Template>(
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchTemplate(by id: UUID) -> Template? {
        let descriptor = FetchDescriptor<Template>(
            predicate: #Predicate { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    // MARK: - Update

    func updateTemplateLastUsed(_ template: Template) {
        template.lastUsedAt = Date()
        try? modelContext.save()
    }

    func updateTemplateName(_ template: Template, name: String) {
        template.name = name
        try? modelContext.save()
    }

    // MARK: - Delete

    func deleteTemplate(_ template: Template) {
        modelContext.delete(template)
        try? modelContext.save()
    }
}
