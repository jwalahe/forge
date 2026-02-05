//
//  CalendarView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: HistoryViewModel
    @State private var selectedDate: Date?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

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
                        // Month navigation
                        monthHeader

                        // Day headers
                        dayHeaders

                        // Calendar grid
                        calendarGrid

                        // Selected date workouts
                        if let selectedDate = selectedDate {
                            selectedDateWorkouts(for: selectedDate)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Calendar")
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

    // MARK: - Subviews

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    changeMonth(by: -1)
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .frame(width: AppConstants.minTouchTarget, height: AppConstants.minTouchTarget)
            }

            Spacer()

            Text(monthYearString)
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    changeMonth(by: 1)
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .frame(width: AppConstants.minTouchTarget, height: AppConstants.minTouchTarget)
            }
        }
        .padding(.horizontal)
    }

    private var dayHeaders: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(calendar.veryShortWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(daysInMonth, id: \.self) { date in
                if let date = date {
                    dayCell(for: date)
                } else {
                    Color.clear
                        .frame(height: AppConstants.minTouchTarget)
                }
            }
        }
    }

    private func dayCell(for date: Date) -> some View {
        let hasWorkout = viewModel.hasWorkout(on: date)
        let isSelected = selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!)
        let isToday = calendar.isDateInToday(date)

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                if hasWorkout {
                    selectedDate = date
                }
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.forgeAccent : Color.clear)
                    .shadow(
                        color: isSelected ? Color.forgeAccent.opacity(0.3) : Color.clear,
                        radius: 6,
                        x: 0,
                        y: 2
                    )

                if isToday && !isSelected {
                    Circle()
                        .stroke(Color.forgeAccent, lineWidth: 2)
                }

                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16))
                    .fontWeight(hasWorkout ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : (hasWorkout ? .primary : .secondary))

                if hasWorkout && !isSelected {
                    Circle()
                        .fill(Color.forgeAccent)
                        .frame(width: 5, height: 5)
                        .offset(y: 16)
                }
            }
            .frame(width: AppConstants.minTouchTarget, height: AppConstants.minTouchTarget)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .disabled(!hasWorkout)
    }

    private func selectedDateWorkouts(for date: Date) -> some View {
        let workouts = viewModel.workouts(on: date)

        return VStack(alignment: .leading, spacing: 12) {
            Text(date.workoutDateString)
                .font(.headline)
                .padding(.horizontal)

            ForEach(workouts) { workout in
                WorkoutRowView(workout: workout)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(AppConstants.cornerRadius)
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Computed Properties

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: viewModel.selectedMonth)
    }

    private var daysInMonth: [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: viewModel.selectedMonth)),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return []
        }

        let daysInMonth = calendar.component(.day, from: monthEnd)
        let firstWeekday = calendar.component(.weekday, from: monthStart)

        var days: [Date?] = []

        // Add empty cells for days before month starts
        for _ in 1..<firstWeekday {
            days.append(nil)
        }

        // Add days of month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }

        return days
    }

    // MARK: - Actions

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: viewModel.selectedMonth) {
            viewModel.selectedMonth = newMonth
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workout.self, configurations: config)
    let context = container.mainContext

    let exercise1 = Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell)

    let workout1 = Workout(startTime: Date().addingTimeInterval(-86400 * 2), endTime: Date().addingTimeInterval(-86400 * 2 + 3600))
    let workout2 = Workout(startTime: Date().addingTimeInterval(-86400 * 5), endTime: Date().addingTimeInterval(-86400 * 5 + 3600))

    context.insert(exercise1)
    context.insert(workout1)
    context.insert(workout2)

    let viewModel = HistoryViewModel(modelContext: context)

    return CalendarView(viewModel: viewModel)
        .modelContainer(container)
}
