//
//  ExerciseHistoryQuickView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/14/26.
//

import SwiftUI
import SwiftData

struct ExerciseHistoryQuickView: View {
    let exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var recentSessions: [(workout: Workout, sets: [ExerciseSet])] = []

    var body: some View {
        NavigationStack {
            List {
                if recentSessions.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("No previous performances for this exercise")
                    )
                } else {
                    ForEach(Array(recentSessions.enumerated()), id: \.offset) { index, session in
                        sessionCard(session: session, index: index)
                    }
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadRecentSessions()
            }
        }
    }

    private func sessionCard(session: (workout: Workout, sets: [ExerciseSet]), index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.workout.startTime.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if index == 0 {
                        Text("Most Recent")
                            .font(.caption2)
                            .foregroundColor(.forgeAccent)
                    } else {
                        Text("\(daysAgo(session.workout.startTime)) days ago")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Total volume
                let volume = session.sets.reduce(0.0) { total, set in
                    total + (set.weight ?? 0) * Double(set.reps ?? 0)
                }
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(volume)) lbs")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("volume")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Sets performed
            VStack(alignment: .leading, spacing: 6) {
                ForEach(session.sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                    HStack {
                        Text("Set \(set.setNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .leading)

                        if let weight = set.weight, let reps = set.reps {
                            Text("\(String(format: "%.1f", weight)) lbs × \(reps)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Spacer()

                        if set.isPersonalRecord {
                            Image(systemName: "trophy.fill")
                                .font(.caption)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.orange, Color.yellow],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func loadRecentSessions() {
        let workoutRepo = WorkoutRepository(modelContext: modelContext)
        let allWorkouts = workoutRepo.fetchAllWorkouts()

        var sessions: [(workout: Workout, sets: [ExerciseSet])] = []

        for workout in allWorkouts.sorted(by: { $0.startTime > $1.startTime }) {
            for workoutExercise in workout.exercises {
                if workoutExercise.exercise?.id == exercise.id {
                    let completedSets = workoutExercise.sets
                        .filter { $0.completedAt != nil }
                        .sorted { $0.setNumber < $1.setNumber }

                    if !completedSets.isEmpty {
                        sessions.append((workout: workout, sets: completedSets))
                    }
                }
            }

            if sessions.count >= 5 {
                break
            }
        }

        recentSessions = sessions
    }

    private func daysAgo(_ date: Date) -> Int {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return max(0, days)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workout.self, configurations: config)
    let context = container.mainContext

    let exercise = Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell)
    context.insert(exercise)

    return ExerciseHistoryQuickView(exercise: exercise)
        .modelContainer(container)
}
