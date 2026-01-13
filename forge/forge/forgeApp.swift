//
//  forgeApp.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI
import SwiftData

@main
struct forgeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Workout.self,
            WorkoutExercise.self,
            ExerciseSet.self,
            Exercise.self,
            Template.self,
            TemplateExercise.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    seedDefaultData()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func seedDefaultData() {
        let context = sharedModelContainer.mainContext
        let exerciseRepo = ExerciseRepository(modelContext: context)
        exerciseRepo.seedDefaultExercises()
    }
}
