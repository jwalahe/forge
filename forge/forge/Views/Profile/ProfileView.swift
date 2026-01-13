//
//  ProfileView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Stats") {
                    HStack {
                        Text("Total Workouts")
                        Spacer()
                        Text("0")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Settings") {
                    NavigationLink("Units") {
                        Text("Units settings")
                    }
                    NavigationLink("Rest Timer Default") {
                        Text("Rest timer settings")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
}
