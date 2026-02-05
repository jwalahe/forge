//
//  CascadeDeleteTests.swift
//  forgeTests
//
//  Tests that cascade deletes properly clean up child records.
//  Data integrity is sacred — orphan records are unacceptable.
//

import Testing
import Foundation
import SwiftData
@testable import forge

@MainActor
@Suite("Cascade Delete Tests")
struct CascadeDeleteTests {
    let container: ModelContainer
    let context: ModelContext

    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Workout.self, WorkoutExercise.self, ExerciseSet.self,
                 Exercise.self, Template.self, TemplateExercise.self,
            configurations: config
        )
        context = container.mainContext
    }

    // MARK: - Helpers

    private func createExercise(name: String = "Bench Press") -> Exercise {
        let exercise = Exercise(name: name, muscleGroup: .chest, equipment: .barbell)
        context.insert(exercise)
        return exercise
    }

    private func createWorkoutWithExercisesAndSets(
        exerciseCount: Int = 3,
        setsPerExercise: Int = 4
    ) -> Workout {
        let workout = Workout()
        context.insert(workout)

        for i in 0..<exerciseCount {
            let exercise = createExercise(name: "Exercise \(i)")
            let workoutExercise = WorkoutExercise(workout: workout, exercise: exercise, order: i)
            context.insert(workoutExercise)
            workout.exercises.append(workoutExercise)

            for j in 0..<setsPerExercise {
                let set = ExerciseSet(
                    workoutExercise: workoutExercise,
                    setNumber: j + 1,
                    weight: 135.0,
                    reps: 8,
                    completedAt: Date()
                )
                context.insert(set)
                workoutExercise.sets.append(set)
            }
        }

        try? context.save()
        return workout
    }

    private func fetchCount<T: PersistentModel>(_ type: T.Type) -> Int {
        let descriptor = FetchDescriptor<T>()
        return (try? context.fetchCount(descriptor)) ?? -1
    }

    // MARK: - Workout Deletion Cascades to WorkoutExercises and ExerciseSets

    @Test("Deleting workout removes all child WorkoutExercises")
    func deleteWorkout_removesAllWorkoutExercises() throws {
        let workout = createWorkoutWithExercisesAndSets(exerciseCount: 3, setsPerExercise: 2)

        // Verify children exist before delete
        let exerciseCountBefore = fetchCount(WorkoutExercise.self)
        #expect(exerciseCountBefore == 3)

        context.delete(workout)
        try context.save()

        let exerciseCountAfter = fetchCount(WorkoutExercise.self)
        #expect(exerciseCountAfter == 0)
    }

    @Test("Deleting workout removes all grandchild ExerciseSets")
    func deleteWorkout_removesAllExerciseSets() throws {
        let workout = createWorkoutWithExercisesAndSets(exerciseCount: 3, setsPerExercise: 4)

        let setCountBefore = fetchCount(ExerciseSet.self)
        #expect(setCountBefore == 12)

        context.delete(workout)
        try context.save()

        let setCountAfter = fetchCount(ExerciseSet.self)
        #expect(setCountAfter == 0)
    }

    @Test("Deleting workout leaves Exercise catalog intact")
    func deleteWorkout_doesNotDeleteExercises() throws {
        let workout = createWorkoutWithExercisesAndSets(exerciseCount: 3, setsPerExercise: 2)

        let exerciseCatalogCount = fetchCount(Exercise.self)
        #expect(exerciseCatalogCount == 3)

        context.delete(workout)
        try context.save()

        let exerciseCatalogCountAfter = fetchCount(Exercise.self)
        #expect(exerciseCatalogCountAfter == 3)
    }

    @Test("No orphan WorkoutExercises or ExerciseSets remain after workout deletion")
    func deleteWorkout_noOrphans() throws {
        _ = createWorkoutWithExercisesAndSets(exerciseCount: 3, setsPerExercise: 4)
        let workout2 = createWorkoutWithExercisesAndSets(exerciseCount: 2, setsPerExercise: 3)

        // Delete only workout2
        context.delete(workout2)
        try context.save()

        // workout1's children should survive: 3 WorkoutExercises, 12 ExerciseSets
        let workoutExerciseCount = fetchCount(WorkoutExercise.self)
        let setCount = fetchCount(ExerciseSet.self)
        #expect(workoutExerciseCount == 3)
        #expect(setCount == 12)
    }

    // MARK: - WorkoutExercise Deletion Cascades to ExerciseSets

    @Test("Deleting a WorkoutExercise removes its child ExerciseSets")
    func deleteWorkoutExercise_removesChildSets() throws {
        let workout = createWorkoutWithExercisesAndSets(exerciseCount: 2, setsPerExercise: 4)

        let exerciseToRemove = workout.exercises.first!

        context.delete(exerciseToRemove)
        try context.save()

        // 1 WorkoutExercise left, 4 sets left (from the other exercise)
        let workoutExerciseCount = fetchCount(WorkoutExercise.self)
        let setCount = fetchCount(ExerciseSet.self)
        #expect(workoutExerciseCount == 1)
        #expect(setCount == 4)
    }

    @Test("Deleting a WorkoutExercise does not delete the parent Workout")
    func deleteWorkoutExercise_parentWorkoutSurvives() throws {
        let workout = createWorkoutWithExercisesAndSets(exerciseCount: 2, setsPerExercise: 2)

        let exerciseToRemove = workout.exercises.first!
        context.delete(exerciseToRemove)
        try context.save()

        let workoutCount = fetchCount(Workout.self)
        #expect(workoutCount == 1)
    }

    // MARK: - Template Deletion Cascades to TemplateExercises

    @Test("Deleting a Template removes all child TemplateExercises")
    func deleteTemplate_removesAllTemplateExercises() throws {
        let template = Template(name: "Push Day")
        context.insert(template)

        for i in 0..<3 {
            let exercise = createExercise(name: "Template Exercise \(i)")
            let templateExercise = TemplateExercise(template: template, exercise: exercise, order: i)
            context.insert(templateExercise)
            template.exercises.append(templateExercise)
        }
        try context.save()

        let templateExerciseCountBefore = fetchCount(TemplateExercise.self)
        #expect(templateExerciseCountBefore == 3)

        context.delete(template)
        try context.save()

        let templateExerciseCountAfter = fetchCount(TemplateExercise.self)
        #expect(templateExerciseCountAfter == 0)
    }

    // MARK: - Repository-Level Deletion

    @Test("WorkoutRepository.deleteWorkout cascades correctly")
    func repositoryDeleteWorkout_cascades() throws {
        let workout = createWorkoutWithExercisesAndSets(exerciseCount: 2, setsPerExercise: 3)
        let repo = WorkoutRepository(modelContext: context)

        repo.deleteWorkout(workout)

        let workoutCount = fetchCount(Workout.self)
        let workoutExerciseCount = fetchCount(WorkoutExercise.self)
        let setCount = fetchCount(ExerciseSet.self)

        #expect(workoutCount == 0)
        #expect(workoutExerciseCount == 0)
        #expect(setCount == 0)
    }
}
