//
//  MainTabView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WorkoutHomeView()
                .tabItem {
                    Label("Workout", systemImage: "figure.strengthtraining.traditional")
                }
                .tag(0)

            HistoryListView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
                .tag(1)

            ExerciseLibraryView()
                .tabItem {
                    Label("Exercises", systemImage: "list.bullet")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(3)
        }
        .onChange(of: selectedTab) { _, _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

#Preview {
    MainTabView()
}
