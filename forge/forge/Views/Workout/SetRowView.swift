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
    @State private var isCompleting = false
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
            // Set number badge with animation
            Text("\(set.setNumber)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    LinearGradient(
                        colors: set.isCompleted
                            ? [Color.forgeAccent, Color.forgeAccent.opacity(0.8)]
                            : [Color.gray, Color.gray.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .scaleEffect(isCompleting ? 1.1 : 1.0)
                .shadow(
                    color: set.isCompleted ? Color.forgeAccent.opacity(0.3) : Color.clear,
                    radius: 6,
                    x: 0,
                    y: 2
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: set.isCompleted)

            // Weight field with enhanced styling
            TextField("", text: $weightText, prompt: Text(previousSetWeightPlaceholder).foregroundColor(.forgeMuted))
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(focusedField == .weight ? 0.08 : 0.02), radius: 4, x: 0, y: 2)
                .frame(width: 85)
                .focused($focusedField, equals: .weight)
                .onChange(of: weightText) { oldValue, newValue in
                    updateSetValues()
                }
                .animation(.easeInOut(duration: 0.2), value: focusedField == .weight)

            // × separator with style
            Text("×")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)

            // Reps field with enhanced styling
            TextField("", text: $repsText, prompt: Text(previousSetRepsPlaceholder).foregroundColor(.forgeMuted))
                .keyboardType(.numberPad)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(focusedField == .reps ? 0.08 : 0.02), radius: 4, x: 0, y: 2)
                .frame(width: 65)
                .focused($focusedField, equals: .reps)
                .onChange(of: repsText) { oldValue, newValue in
                    updateSetValues()
                }
                .animation(.easeInOut(duration: 0.2), value: focusedField == .reps)

            // Progress arrow with animation
            progressArrow
                .frame(width: 24)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.getProgressIndicator(currentSet: set, previousSet: previousSet))

            // PR trophy indicator
            if set.isPersonalRecord {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color.yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.orange.opacity(0.4), radius: 4, x: 0, y: 2)
                    .transition(.scale.combined(with: .opacity))
                    .frame(width: 24)
            }

            // Checkmark button with enhanced animation
            Button {
                completeSet()
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28))
                    .foregroundColor(set.isCompleted ? .forgeSuccess : .secondary.opacity(0.5))
                    .scaleEffect(isCompleting ? 1.2 : 1.0)
                    .shadow(
                        color: set.isCompleted ? Color.forgeSuccess.opacity(0.3) : Color.clear,
                        radius: 6,
                        x: 0,
                        y: 2
                    )
            }
            .frame(width: 44, height: 44)
        }
        .padding(.vertical, 6)
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
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.forgeSuccess, Color.forgeSuccess.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.forgeSuccess.opacity(0.3), radius: 4, x: 0, y: 2)
            case .down:
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.forgeWarning, Color.forgeWarning.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.forgeWarning.opacity(0.3), radius: 4, x: 0, y: 2)
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

        // Animate completion
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isCompleting = true
        }

        // Complete the set
        viewModel.completeSet(set)

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Dismiss keyboard
        focusedField = nil

        // Reset animation state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                isCompleting = false
            }
        }
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
