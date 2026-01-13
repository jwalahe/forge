//
//  ProfileView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var historyViewModel: HistoryViewModel?
    @AppStorage(SettingsKey.weightUnit.rawValue) private var weightUnit: WeightUnit = .lbs
    @AppStorage(SettingsKey.defaultRestTimer.rawValue) private var defaultRestTimer: Int = 90

    var body: some View {
        NavigationStack {
            List {
                // Stats Section
                Section {
                    if let viewModel = historyViewModel {
                        statsGrid(viewModel: viewModel)
                    }
                } header: {
                    Text("Your Stats")
                        .font(.headline)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                // Settings Section
                Section("Preferences") {
                    Picker("Weight Unit", selection: $weightUnit) {
                        Text("lbs").tag(WeightUnit.lbs)
                        Text("kg").tag(WeightUnit.kg)
                    }

                    Picker("Default Rest Timer", selection: $defaultRestTimer) {
                        Text("60 seconds").tag(60)
                        Text("90 seconds").tag(90)
                        Text("2 minutes").tag(120)
                        Text("3 minutes").tag(180)
                    }
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/anthropics/forge")!) {
                        HStack {
                            Text("Give Feedback")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                setupViewModel()
            }
        }
    }

    // MARK: - Subviews

    private func statsGrid(viewModel: HistoryViewModel) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCardCompact(
                icon: "calendar",
                title: "Workouts",
                value: "\(viewModel.totalWorkouts())",
                color: .blue
            )

            StatCardCompact(
                icon: "scalemass",
                title: "Total Volume",
                value: String(format: "%.0fk", viewModel.totalVolume() / 1000),
                color: .orange
            )

            StatCardCompact(
                icon: "flame.fill",
                title: "Current Streak",
                value: "\(viewModel.currentStreak()) days",
                color: .red
            )

            StatCardCompact(
                icon: "chart.line.uptrend.xyaxis",
                title: "This Week",
                value: "\(workoutsThisWeek(viewModel))",
                color: .green
            )
        }
        .padding()
    }

    // MARK: - Helpers

    private func setupViewModel() {
        if historyViewModel == nil {
            historyViewModel = HistoryViewModel(modelContext: modelContext)
        }
    }

    private func workoutsThisWeek(_ viewModel: HistoryViewModel) -> Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return 0
        }

        return viewModel.workouts.filter { workout in
            workout.startTime >= weekStart && workout.startTime <= now
        }.count
    }
}

// MARK: - Stat Card Compact

struct StatCardCompact: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workout.self, configurations: config)

    return ProfileView()
        .modelContainer(container)
}
