//
//  SetRowView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI
import SwiftData

struct SetRowView: View {
    let set: ExerciseSet
    let previousSet: ExerciseSet?
    let viewModel: ActiveWorkoutViewModel

    @State private var weightText: String
    @State private var repsText: String
    @FocusState private var focusedField: Field?

    init(set: ExerciseSet, previousSet: ExerciseSet?, viewModel: ActiveWorkoutViewModel) {
        self.set = set
        self.previousSet = previousSet
        self.viewModel = viewModel

        // Initialize with current values or empty
        _weightText = State(initialValue: set.weight.map { String(format: "%.1f", $0) } ?? "")
        _repsText = State(initialValue: set.reps.map { String($0) } ?? "")
    }

    var body: some View {
        HStack(spacing: 12) {
            // Set number badge
            Text("\(set.setNumber)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(set.isCompleted ? Color.forgeAccent : Color.gray)
                .clipShape(Circle())

            // Weight field
            TextField("", text: $weightText, prompt: Text(previousSetWeightPlaceholder).foregroundColor(.forgeMuted))
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .frame(width: 80)
                .focused($focusedField, equals: .weight)
                .onChange(of: weightText) { oldValue, newValue in
                    updateSetValues()
                }

            // × separator
            Text("×")
                .foregroundColor(.secondary)

            // Reps field
            TextField("", text: $repsText, prompt: Text(previousSetRepsPlaceholder).foregroundColor(.forgeMuted))
                .keyboardType(.numberPad)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .frame(width: 60)
                .focused($focusedField, equals: .reps)
                .onChange(of: repsText) { oldValue, newValue in
                    updateSetValues()
                }

            // Progress arrow
            progressArrow
                .frame(width: 20)

            // Checkmark button
            Button {
                completeSet()
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(set.isCompleted ? .forgeSuccess : .secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Computed Properties

    private var previousSetWeightPlaceholder: String {
        guard let weight = previousSet?.weight else { return "0" }
        return String(format: "%.1f", weight)
    }

    private var previousSetRepsPlaceholder: String {
        guard let reps = previousSet?.reps else { return "0" }
        return String(reps)
    }

    private var progressArrow: some View {
        let indicator = viewModel.getProgressIndicator(currentSet: set, previousSet: previousSet)

        return Group {
            switch indicator {
            case .up:
                Image(systemName: "arrow.up")
                    .foregroundColor(.forgeSuccess)
                    .fontWeight(.bold)
            case .down:
                Image(systemName: "arrow.down")
                    .foregroundColor(.forgeWarning)
                    .fontWeight(.bold)
            case .none:
                EmptyView()
            }
        }
    }

    // MARK: - Actions

    private func updateSetValues() {
        let weight = Double(weightText)
        let reps = Int(repsText)
        viewModel.updateSet(set, weight: weight, reps: reps)
    }

    private func completeSet() {
        // Ensure values are set
        updateSetValues()

        // Complete the set
        viewModel.completeSet(set)

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Dismiss keyboard
        focusedField = nil
    }

    enum Field {
        case weight
        case reps
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workout.self, configurations: config)
    let context = container.mainContext

    let exercise = Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell)
    let workout = Workout()
    let workoutExercise = WorkoutExercise(workout: workout, exercise: exercise, order: 0)
    let set = ExerciseSet(workoutExercise: workoutExercise, setNumber: 1, weight: 185, reps: 8)
    let previousSet = ExerciseSet(workoutExercise: workoutExercise, setNumber: 1, weight: 180, reps: 8)

    context.insert(exercise)
    context.insert(workout)
    context.insert(workoutExercise)
    context.insert(set)

    let viewModel = ActiveWorkoutViewModel(modelContext: context)

    return SetRowView(set: set, previousSet: previousSet, viewModel: viewModel)
        .padding()
}
